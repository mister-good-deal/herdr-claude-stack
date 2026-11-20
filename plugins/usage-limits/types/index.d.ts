export type Limit = { kind: string; percentUsed: number; resetsAt?: string }
export type Account = { email: string; plan: string | null }
// compact: the auto-compact window in tokens, absent when auto-compaction is off
export type Ctx = { tokens?: number; window: number; percent?: number; compact?: number }
// prompts sent since `since` ($.session.usage().startedAt), so /clear starts over and a reload does not
export type Msgs = { since: number; n: number }
// effort: what the main loop's last request carried; null before the first one or on a model without effort
export type Effort = string | number | null

declare module 'claude-code' {
  interface PluginState {
    'usage-limits': { limits: Limit[]; now: number; account: Account | null; ctx: Ctx | null; msgs: Msgs; model: string; effort: Effort }
  }
}
