import { expect, test } from 'claude-code/testing'

import { centerGap, engineLabel, fmtReset, fmtTokens, gauges, planName, segments } from '../hooks/register'

const T = Date.parse('2026-10-09T12:00:00Z')
// a local date, so the expected text holds in any timezone: Monday 12 October 2026, 09:05
const RESET = new Date(2026, 9, 12, 9, 5).toISOString()
const text = (rs: { t: string }[][]) => rs.map(s => s.map(r => r.t).join('')).join(' │ ')

test('gauges', () => {
  expect(gauges([], T)).toEqual([])
  expect(gauges([
    { kind: 'five_hour', percentUsed: 42.4, resetsAt: '2026-10-09T14:13:00Z' },
    { kind: 'seven_day', percentUsed: 18, resetsAt: RESET },
  ], T)).toEqual([
    { tag: '⁵ʰ', glyph: '◑', pct: 42, color: 'success', eta: '2h13' },
    { tag: '⁷ʲ', glyph: '◔', pct: 18, color: 'success', eta: 'lun. 12 09:05' },
  ])
  expect(gauges([{ kind: 'five_hour', percentUsed: 90, resetsAt: '2026-10-09T12:07:30Z' }], T))
    .toEqual([{ tag: '⁵ʰ', glyph: '●', pct: 90, color: 'error', eta: '8m' }])
  expect(gauges([{ kind: 'five_hour', percentUsed: 90, resetsAt: '2026-10-09T11:00:00Z' }], T))
    .toEqual([{ tag: '⁵ʰ', glyph: '○', pct: 0, color: 'success', eta: undefined }])
  expect(gauges([{ kind: 'seven_day', percentUsed: 65 }], T)).toEqual([{ tag: '⁷ʲ', glyph: '◕', pct: 65, color: 'warning', eta: undefined }])
  expect(fmtReset(new Date(2026, 10, 27, 0, 0).getTime())).toBe('ven. 27 00:00')
})

test('no 5h gauge on Claude Ultra', () => {
  const rl = [{ kind: 'five_hour', percentUsed: 42 }, { kind: 'seven_day', percentUsed: 18 }]
  expect(gauges(rl, T, 'Claude Ultra').map(g => g.tag)).toEqual(['⁷ʲ'])
  expect(gauges(rl, T, 'Claude Max x20').map(g => g.tag)).toEqual(['⁵ʰ', '⁷ʲ'])
})

test('segments', () => {
  const gs = gauges([{ kind: 'five_hour', percentUsed: 42.4, resetsAt: '2026-10-09T14:13:00Z' }, { kind: 'seven_day', percentUsed: 18 }], T)
  expect(text(segments(12, { tokens: 84_321, window: 200_000, percent: 42 }, gs))).toBe('❯  12 │ ⛁  84k/200k │ ⁵ʰ◑ 42% ↻ 2h13 │ ⁷ʲ◔ 18%')
  expect(text(segments(3, { tokens: 84_321, window: 1_000_000, percent: 8, compact: 150_000 }, []))).toBe('❯  3 │ ⛁  84k/1M ⇥ 150k')
  expect(text(segments(0, { window: 1_000_000 }, []))).toBe('❯  0')
  expect(segments(3, { tokens: 900_000, window: 1_000_000, percent: 90 }, [])[1]?.[0]?.color).toBe('error')
  expect(fmtTokens(1_000_000)).toBe('1M')
  expect(fmtTokens(1_250_000)).toBe('1.3M')
  expect(fmtTokens(512)).toBe('512')
})

test('centerGap', () => {
  // 100 cols, account 20 wide starts at 40, ends at 60; right part 18 wide ends at 98 → starts at 80 → 20 spaces
  expect(centerGap(100, 20, 18)).toBe(20)
  expect(centerGap(40, 20, 18)).toBe(3)
  expect(centerGap(undefined, 20, 18)).toBe(3)
})

test('planName', () => {
  expect(planName('claude_max', 'default_claude_max_20x', 'Ultra')).toBe('Claude Ultra')
  expect(planName('claude_max', 'default_claude_max_20x')).toBe('Claude Max x20')
  expect(planName('claude_max', 'default_claude_max_5x')).toBe('Claude Max x5')
  expect(planName('claude_pro', 'default_claude_ai')).toBe('Claude Pro')
  expect(planName(null, null)).toBe(null)
})

test('engineLabel', () => {
  expect(engineLabel('claude-fable-5-2[1m]', 'high')).toBe('Fable 5.2 · high')
  expect(engineLabel('claude-opus-4-5-20251101', null)).toBe('Opus 4.5')
  expect(engineLabel('claude-fable-5', 'xhigh')).toBe('Fable 5 · xhigh')
  expect(engineLabel('gateway/some-model', 'low')).toBe('gateway/some-model · low')
  expect(engineLabel('', 'high')).toBe('')
})

// the hooks under these stand for the engine: a session on a 150k compaction window whose first request goes out at `high`
test('the hint line ends with the model and its effort once a request has gone out', async ($, on) => {
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.usage', () => ({ value: {
    startedAt: 1,
    rateLimits: [],
    context: { window: 1_000_000, tokens: 84_321, percent: 8, breakdown: { isAutoCompactEnabled: true, rawMaxTokens: 150_000 } },
  } } as never))
  on('session.model', () => ({ value: 'claude-fable-5-2' }) as never)
  on('clock.now', () => ({ value: T }) as never)
  on('clock.every', () => ({ value: undefined }) as never)
  on('env.get', () => ({ value: undefined }) as never)
  on('turn.step', async function* (_, e) { return { turnId: e.turnId, index: e.index, answer: '', toolUses: [] } as never })
  on('ui.render', { component: 'PromptHint' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>{`${e.props.hint}${e.props.tail ?? ''}`}</Text>
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  const HINT = { plugin: 'usage-limits', component: 'PromptHint', surface: 'terminal', props: { isDraft: false, isWorking: false, hint: '? for shortcuts' } } as const
  let ui = await $.ui.mount(HINT)
  expect((await ui.find({ type: 'Text' }))?.text).toBe('? for shortcutsFable 5.2')
  await ui.unmount()

  for await (const _ of $.turn.step({ turnId: 't', index: 0, model: 'claude-fable-5-2', effort: 'high', messageCount: 1 })) void _
  ui = await $.ui.mount(HINT)
  expect((await ui.find({ type: 'Text' }))?.text).toBe('? for shortcutsFable 5.2 · high')
  await ui.unmount()
})
