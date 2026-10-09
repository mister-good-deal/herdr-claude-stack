export type Limit = { kind: string; percentUsed: number; resetsAt?: string }
export type Account = { email: string; plan: string | null }
export type Ctx = { tokens?: number; window: number; percent?: number }
// prompts sent since `since` ($.session.usage().startedAt), so /clear starts over and a reload does not
export type Msgs = { since: number; n: number }

declare module 'claude-code' {
  interface PluginState {
    'usage-limits': { limits: Limit[]; now: number; account: Account | null; ctx: Ctx | null; msgs: Msgs }
  }
}
