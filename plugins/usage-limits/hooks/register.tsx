import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Account, Ctx, Limit, Msgs } from '../types'

const limits = atom({ plugin: 'usage-limits', key: 'limits' } as const, [] as Limit[])
const now = atom({ plugin: 'usage-limits', key: 'now' } as const, 0)
const account = atom({ plugin: 'usage-limits', key: 'account' } as const, null as Account | null)
const ctx = atom({ plugin: 'usage-limits', key: 'ctx' } as const, null as Ctx | null)
const msgs = atom({ plugin: 'usage-limits', key: 'msgs' } as const, { since: 0, n: 0 } as Msgs)

// calibration knobs: cells between the footer's right edge and the terminal's;
// what follows a symbol icon (Ghostty ≥1.2 lets a symbol spill into one blank cell after it; ' ' elsewhere)
const RIGHT_PAD = 2
const ICON_GAP = '  '

export type Run = { t: string; color?: ThemeKey; dim?: boolean }
export type Gauge = { tag: string; glyph: string; pct: number; color: ThemeKey; eta?: string }

const tone = (pct: number): ThemeKey => (pct < 50 ? 'success' : pct < 80 ? 'warning' : 'error')

const gauge = (tag: string, pct: number, eta?: string): Gauge => ({
  tag,
  glyph: '○◔◑◕●'[Math.min(4, Math.round(pct / 25))]!,
  pct: Math.round(pct),
  color: tone(pct),
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

export const fmtTokens = (n: number) => (n >= 1e6 ? `${+(n / 1e6).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}k` : `${n}`)

// right side, one run list per segment: ❯ prompts sent │ ⛁ context │ 5h gauge │ weekly gauge
export function segments(n: number, c: Ctx | null, gs: readonly Gauge[]): Run[][] {
  const segs: Run[][] = [[{ t: `❯${ICON_GAP}`, color: 'claude' }, { t: `${n}` }]]
  if (c?.tokens !== undefined) {
    segs.push([{ t: `⛁${ICON_GAP}${fmtTokens(c.tokens)}`, color: tone(c.percent ?? 0) }, { t: `/${fmtTokens(c.window)}`, dim: true }])
  }
  for (const g of gs) segs.push([{ t: `${g.tag}${g.glyph} ${g.pct}%`, color: g.color }, ...(g.eta ? [{ t: ` ↻ ${g.eta}`, dim: true }] : [])])
  return segs
}

const width = (rs: readonly Run[]) => rs.reduce((w, r) => w + r.t.length, 0)

// spaces between the account and the right side so the account sits mid-screen; 3 when the terminal is too narrow
// ponytail: counts one cell per UTF-16 unit, right for these glyphs and an ASCII email
export const centerGap = (cols: number | undefined, accountW: number, rightW: number) =>
  Math.max(3, cols ? cols - RIGHT_PAD - rightW - Math.floor((cols - accountW) / 2) - accountW : 0)

// claude_max + default_claude_max_20x → "Claude Max x20"; null off a Claude plan
export function planName(type?: string | null, tier?: string | null): string | null {
  if (!type?.startsWith('claude_')) return null
  const x = tier?.match(/_(\d+)x$/)?.[1]
  return `Claude ${type.slice(7).replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}${x ? ` x${x}` : ''}`
}

// oauthAccount from the global config; null on an API key or a config without one
async function readAccount($: EngineInterface): Promise<Account | null> {
  const dir = (await $.env.get('CLAUDE_CONFIG_DIR')) ?? (await $.env.get('HOME'))
  try {
    const oa = JSON.parse(await $.fs.read(`${dir}/.claude.json`)).oauthAccount
    return oa?.emailAddress ? { email: oa.emailAddress, plan: planName(oa.organizationType, oa.organizationRateLimitTier) } : null
  } catch {
    return null
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const usage = await $.session.usage()
    const t = await $.clock.now()
    const acct = await readAccount($)
    await update($, limits, () => usage.rateLimits)
    await update($, ctx, () => usage.context)
    await update($, now, () => t)
    await update($, account, () => acct)
    // a reload keeps the count; /clear (a new startedAt) starts it over
    await update($, msgs, m => (m.since === usage.startedAt ? m : { since: usage.startedAt, n: 0 }))
    // ponytail: 30s tick only to move the countdown; percentages come from session.measure
    $.clock.every(30_000, () => void $.clock.now().then(t => update($, now, () => t)))
    return result
  })

  // the person's own prompts (typed, or through Remote Control), not notifications, peers or schedules
  on('prompt.submit', async ($, e, next) => {
    if (e.origin.kind === 'composer' || e.origin.kind === 'bridge') {
      const { startedAt } = await $.session.usage()
      await update($, msgs, m => ({ since: startedAt, n: m.since === startedAt ? m.n + 1 : 1 }))
    }
    return next(e)
  })

  // pushed after each turn and whenever a window moves a whole point; re-reads the account so a /login shows
  on('session.measure', async ($, e, next) => {
    const t = await $.clock.now()
    const acct = await readAccount($)
    await update($, limits, () => e.rateLimits)
    await update($, ctx, () => e.context)
    await update($, now, () => t)
    await update($, account, () => acct)
    return next(e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const acct = await read($, account)
    const segs = segments((await read($, msgs)).n, await read($, ctx), gauges(await read($, limits), await read($, now)))

    const right: Run[] = e.props.modes.length ? [{ t: `${e.props.modes.join(' & ')}  `, dim: true }] : []
    segs.forEach((s, i) => right.push(...(i ? [{ t: ' │ ', dim: true }] : []), ...s))
    const left: Run[] = acct
      ? [{ t: `☺${ICON_GAP}`, color: 'claude' }, { t: acct.email }, ...(acct.plan ? [{ t: ' / ', dim: true }, { t: acct.plan }] : [])]
      : []
    const last = left.at(-1)
    if (last) left[left.length - 1] = { ...last, t: last.t + ' '.repeat(centerGap(e.viewport?.columns, width(left), width(right))) }

    const { Text } = $.ui.resolve(e)
    return (
      <Text>
        {[...left, ...right].map((r, i) => (
          <Text key={`r${i}`} {...(r.color ? { color: r.color } : r.dim ? { dimColor: true } : {})}>
            {r.t}
          </Text>
        ))}
      </Text>
    )
  })
}
