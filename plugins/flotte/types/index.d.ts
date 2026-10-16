export type Lieutenant = {
  nom: string
  machine: string
  etat: string
  branche: string
  mr: string
}

declare module 'claude-code' {
  interface PluginState {
    flotte: { lieutenants: Lieutenant[]; masque: boolean }
  }
}
