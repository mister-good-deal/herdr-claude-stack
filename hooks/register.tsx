import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Limit } from '../types'

const limits = atom({ plugin: 'usage-limits', key: 'limits' } as const, [] as Limit[])
const now = atom({ plugin: 'usage-limits', key: 'now' } as const, 0)
const email = atom({ plugin: 'usage-limits', key: 'email' } as const, null as string | null)

// calibration knob: cells between the footer's right edge and the terminal's
const RIGHT_PAD = 2

export type Gauge = { tag: string; glyph: string; pct: number; color: ThemeKey; eta?: string }

const gauge = (tag: string, pct: number, eta?: string): Gauge => ({
  tag,
  glyph: '○◔◑◕●'[Math.min(4, Math.round(pct / 25))]!,
  pct: Math.round(pct),
  color: pct < 50 ? 'success' : pct < 80 ? 'warning' : 'error',
  eta,
})

// [5h window with countdown, weekly window]; empty when no window has a reading (API key, before the first response)
export function gauges(rl: readonly Limit[], t: number): Gauge[] {
  const out: Gauge[] = []
  const five = rl.find(r => r.kind === 'five_hour')
  if (five) {
    const left = five.resetsAt ? Date.parse(five.resetsAt) - t : NaN
    if (left <= 0) {
      out.push(gauge('⁵ʰ', 0)) // window reset since the last reading
    } else {
      const m = Math.ceil(left / 60_000)
      out.push(gauge('⁵ʰ', five.percentUsed, Number.isNaN(m) ? undefined : m >= 60 ? `${Math.floor(m / 60)}h${String(m % 60).padStart(2, '0')}` : `${m}m`))
    }
  }
  const week = rl.find(r => r.kind === 'seven_day')
  if (week) out.push(gauge('⁷ʲ', week.percentUsed))
  return out
}

const gaugeText = (g: Gauge) => `${g.tag}${g.glyph} ${g.pct}%${g.eta ? ` ↻ ${g.eta}` : ''}`

// spaces between the account and the gauges so the account sits mid-screen; 3 when the terminal is too narrow
// ponytail: counts one cell per UTF-16 unit, right for these glyphs and an ASCII email
export const centerGap = (cols: number | undefined, accountW: number, rightW: number) =>
  Math.max(3, cols ? cols - RIGHT_PAD - rightW - Math.floor((cols - accountW) / 2) - accountW : 0)

// oauthAccount from the global config; null on an API key or a config without one
async function readEmail($: EngineInterface): Promise<string | null> {
  const dir = (await $.env.get('CLAUDE_CONFIG_DIR')) ?? (await $.env.get('HOME'))
  try {
    return JSON.parse(await $.fs.read(`${dir}/.claude.json`)).oauthAccount?.emailAddress ?? null
  } catch {
    return null
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const { rateLimits } = await $.session.usage()
    const t = await $.clock.now()
    const mail = await readEmail($)
    await update($, limits, () => rateLimits)
    await update($, now, () => t)
    await update($, email, () => mail)
    // ponytail: 30s tick only to move the countdown; percentages come from session.measure
    $.clock.every(30_000, () => void $.clock.now().then(t => update($, now, () => t)))
    return result
  })

  // pushed after each response and whenever a window moves a whole point; re-reads the account so a /login shows
  on('session.measure', async ($, e, next) => {
    const t = await $.clock.now()
    const mail = await readEmail($)
    await update($, limits, () => e.rateLimits)
    await update($, now, () => t)
    await update($, email, () => mail)
    return next(e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const gs = gauges(await read($, limits), await read($, now))
    const mail = await read($, email)
    if (!gs.length && !mail) return next(e)

    const modes = e.props.modes.length ? `${e.props.modes.join(' & ')}  ` : ''
    const rightW = modes.length + gs.map(gaugeText).join(' │ ').length
    const { Text } = $.ui.resolve(e)
    return (
      <Text>
        {mail && <Text><Text color="claude">☺</Text> {mail}{' '.repeat(centerGap(e.viewport?.columns, mail.length + 2, rightW))}</Text>}
        {modes && <Text dimColor>{modes}</Text>}
        {gs.map((g, i) => (
          <Text key={`g${i}`}>
            {i > 0 && <Text dimColor> │ </Text>}
            <Text color={g.color}>{g.tag}{g.glyph} {g.pct}%</Text>
            {g.eta && <Text dimColor> ↻ {g.eta}</Text>}
          </Text>
        ))}
      </Text>
    )
  })
}
