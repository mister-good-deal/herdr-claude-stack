export type Limit = { kind: string; percentUsed: number; resetsAt?: string }
export type Account = { email: string; plan: string | null }

declare module 'claude-code' {
  interface PluginState {
    'usage-limits': { limits: Limit[]; now: number; account: Account | null }
  }
}
