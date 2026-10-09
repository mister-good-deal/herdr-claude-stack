import { expect, test } from 'claude-code/testing'

import { centerGap, gauges, planName } from '../hooks/register'

const T = Date.parse('2026-10-09T12:00:00Z')

test('gauges', () => {
  expect(gauges([], T)).toEqual([])
  expect(gauges([
    { kind: 'five_hour', percentUsed: 42.4, resetsAt: '2026-10-09T14:13:00Z' },
    { kind: 'seven_day', percentUsed: 18, resetsAt: '2026-10-12T00:00:00Z' },
  ], T)).toEqual([
    { tag: '⁵ʰ', glyph: '◑', pct: 42, color: 'success', eta: '2h13' },
    { tag: '⁷ʲ', glyph: '◔', pct: 18, color: 'success', eta: undefined },
  ])
  expect(gauges([{ kind: 'five_hour', percentUsed: 90, resetsAt: '2026-10-09T12:07:30Z' }], T))
    .toEqual([{ tag: '⁵ʰ', glyph: '●', pct: 90, color: 'error', eta: '8m' }])
  expect(gauges([{ kind: 'five_hour', percentUsed: 90, resetsAt: '2026-10-09T11:00:00Z' }], T))
    .toEqual([{ tag: '⁵ʰ', glyph: '○', pct: 0, color: 'success', eta: undefined }])
  expect(gauges([{ kind: 'seven_day', percentUsed: 65 }], T)[0]?.color).toBe('warning')
})

test('centerGap', () => {
  // 100 cols, account 20 wide starts at 40, ends at 60; right part 18 wide ends at 98 → starts at 80 → 20 spaces
  expect(centerGap(100, 20, 18)).toBe(20)
  expect(centerGap(40, 20, 18)).toBe(3)
  expect(centerGap(undefined, 20, 18)).toBe(3)
})

test('planName', () => {
  expect(planName('claude_max', 'default_claude_max_20x')).toBe('Claude Max x20')
  expect(planName('claude_max', 'default_claude_max_5x')).toBe('Claude Max x5')
  expect(planName('claude_pro', 'default_claude_ai')).toBe('Claude Pro')
  expect(planName(null, null)).toBe(null)
})
