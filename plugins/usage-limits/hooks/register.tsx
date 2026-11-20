import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, ThemeKey } from 'claude-code'

import type { Account, Ctx, Effort, Limit, Msgs } from '../types'

const limits = atom({ plugin: 'usage-limits', key: 'limits' } as const, [] as Limit[])
const now = atom({ plugin: 'usage-limits', key: 'now' } as const, 0)
const account = atom({ plugin: 'usage-limits', key: 'account' } as const, null as Account | null)
const ctx = atom({ plugin: 'usage-limits', key: 'ctx' } as const, null as Ctx | null)
const msgs = atom({ plugin: 'usage-limits', key: 'msgs' } as const, { since: 0, n: 0 } as Msgs)
const model = atom({ plugin: 'usage-limits', key: 'model' } as const, '')
const effort = atom({ plugin: 'usage-limits', key: 'effort' } as const, null as Effort)

// calibration knobs: cells between the footer's right edge and the terminal's;
// what follows a symbol icon (Ghostty ≥1.2 lets a symbol spill into one blank cell after it; ' ' elsewhere)
const RIGHT_PAD = 2
const ICON_GAP = '  '

// the plan with no 5h window: its gauge is never drawn, even on a stale reading
const NO_FIVE_HOUR = 'Claude Ultra'
const DAYS = ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.']

export type Run = { t: string; color?: ThemeKey; dim?: boolean }
export type Gauge = { tag: string; glyph: string; pct: number; color: ThemeKey; eta?: string }

const tone = (pct: number): ThemeKey => (pct < 50 ? 'success' : pct < 80 ? 'warning' : 'error')
const pad2 = (n: number) => String(n).padStart(2, '0')

const gauge = (tag: string, pct: number, eta?: string): Gauge => ({
  tag,
  glyph: '○◔◑◕●'[Math.min(4, Math.round(pct / 25))]!,
  pct: Math.round(pct),
  color: tone(pct),
  eta,
})

// time left before a reset: "2h13", "8m"
const countdown = (ms: number) => {
  const m = Math.ceil(ms / 60_000)
  return m >= 60 ? `${Math.floor(m / 60)}h${pad2(m % 60)}` : `${m}m`
}

// the moment of a reset in the machine's timezone: "ven. 27 00:00" (a weekly reset is under 7 days away, so no month)
export const fmtReset = (at: number) => {
  const d = new Date(at)
  return `${DAYS[d.getDay()]} ${d.getDate()} ${pad2(d.getHours())}:${pad2(d.getMinutes())}`
}

// [5h window with its countdown, weekly window with its reset date]; a window without a reading has no gauge
// (API key, before the first response, the 5h window on a plan that has none)
export function gauges(rl: readonly Limit[], t: number, plan?: string | null): Gauge[] {
  const out: Gauge[] = []
  for (const kind of plan === NO_FIVE_HOUR ? ['seven_day'] : ['five_hour', 'seven_day']) {
    const r = rl.find(r => r.kind === kind)
    if (!r) continue
    const tag = kind === 'five_hour' ? '⁵ʰ' : '⁷ʲ'
    const at = r.resetsAt ? Date.parse(r.resetsAt) : NaN
    if (at <= t) out.push(gauge(tag, 0)) // window reset since the last reading
    else out.push(gauge(tag, r.percentUsed, Number.isNaN(at) ? undefined : kind === 'five_hour' ? countdown(at - t) : fmtReset(at)))
  }
  return out
}

export const fmtTokens = (n: number) => (n >= 1e6 ? `${+(n / 1e6).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}k` : `${n}`)

// right side, one run list per segment: ❯ prompts sent │ ⛁ context ⇥ auto-compact window │ 5h gauge │ weekly gauge
export function segments(n: number, c: Ctx | null, gs: readonly Gauge[]): Run[][] {
  const segs: Run[][] = [[{ t: `❯${ICON_GAP}`, color: 'claude' }, { t: `${n}` }]]
  if (c?.tokens !== undefined) {
    segs.push([
      { t: `⛁${ICON_GAP}${fmtTokens(c.tokens)}`, color: tone(c.percent ?? 0) },
      { t: `/${fmtTokens(c.window)}${c.compact ? ` ⇥ ${fmtTokens(c.compact)}` : ''}`, dim: true },
    ])
  }
  for (const g of gs) segs.push([{ t: `${g.tag}${g.glyph} ${g.pct}%`, color: g.color }, ...(g.eta ? [{ t: ` ↻ ${g.eta}`, dim: true }] : [])])
  return segs
}

const width = (rs: readonly Run[]) => rs.reduce((w, r) => w + r.t.length, 0)

// spaces between the account and the right side so the account sits mid-screen; 3 when the terminal is too narrow
// ponytail: counts one cell per UTF-16 unit, right for these glyphs and an ASCII email
export const centerGap = (cols: number | undefined, accountW: number, rightW: number) =>
  Math.max(3, cols ? cols - RIGHT_PAD - rightW - Math.floor((cols - accountW) / 2) - accountW : 0)

// the account's own display name ("Ultra" → "Claude Ultra"); a config without one:
// claude_max + default_claude_max_20x → "Claude Max x20"; null off a Claude plan
export function planName(type?: string | null, tier?: string | null, display?: string | null): string | null {
  if (display) return `Claude ${display}`
  if (!type?.startsWith('claude_')) return null
  const x = tier?.match(/_(\d+)x$/)?.[1]
  return `Claude ${type.slice(7).replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}${x ? ` x${x}` : ''}`
}

// claude-fable-5-2[1m] → "Fable 5.2", with the effort when one is known: "Fable 5.2 · high"
// ponytail: an id of another shape (claude-3-5-sonnet-…, a gateway's) is shown as it is
export function engineLabel(id: string, e: Effort): string {
  const m = id.match(/^claude-([a-z]+)-(\d+(?:-\d{1,2})*)(?:-\d{8})?(?:\[.*\])?$/)
  const name = m ? `${m[1]![0]!.toUpperCase()}${m[1]!.slice(1)} ${m[2]!.replace(/-/g, '.')}` : id
  return e === null || !name ? name : `${name} · ${e}`
}

// oauthAccount from the global config; null on an API key or a config without one
async function readAccount($: EngineInterface): Promise<Account | null> {
  const dir = (await $.env.get('CLAUDE_CONFIG_DIR')) ?? (await $.env.get('HOME'))
  try {
    const oa = JSON.parse(await $.fs.read(`${dir}/.claude.json`)).oauthAccount
    return oa?.emailAddress
      ? { email: oa.emailAddress, plan: planName(oa.organizationType, oa.organizationRateLimitTier, oa.planDisplayName) }
      : null
  } catch {
    return null
  }
}

// everything the footer reads off the engine and the account, re-read so a /login or a /model shows;
// the summary breakdown is estimated locally (no request) and only its compaction window is kept
async function refresh($: EngineInterface) {
  const usage = await $.session.usage({ breakdown: 'summary' })
  const { tokens, window, percent, breakdown } = usage.context
  const t = await $.clock.now()
  const acct = await readAccount($)
  const id = await $.session.model()
  await update($, limits, () => usage.rateLimits)
  await update($, ctx, () => ({
    window,
    ...(tokens !== undefined && { tokens }),
    ...(percent !== undefined && { percent }),
    ...(breakdown?.isAutoCompactEnabled && { compact: breakdown.rawMaxTokens }),
  }))
  await update($, now, () => t)
  await update($, account, () => acct)
  await update($, model, () => id)
  return usage
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const { startedAt } = await refresh($)
    // a reload keeps the count; /clear (a new startedAt) starts it over
    await update($, msgs, m => (m.since === startedAt ? m : { since: startedAt, n: 0 }))
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

  // pushed after each turn and whenever a window moves a whole point
  on('session.measure', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  // the main loop's requests say the effort in force, the one figure the engine gives nowhere else
  on('turn.step', async function* ($, e, next) {
    if (e.agentId === undefined) {
      const id = await $.session.model()
      await update($, model, () => id)
      await update($, effort, () => e.effort ?? null)
    }
    return yield* next(e)
  })

  // bottom left, after the engine's own hint line: the session's model and effort
  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const label = engineLabel(await read($, model), await read($, effort))
    return next(label ? { ...e, props: { ...e.props, tail: [e.props.tail, label].filter(Boolean).join(' · ') } } : e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const acct = await read($, account)
    const segs = segments((await read($, msgs)).n, await read($, ctx), gauges(await read($, limits), await read($, now), acct?.plan))

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
