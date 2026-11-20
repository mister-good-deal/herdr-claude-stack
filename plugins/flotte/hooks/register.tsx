import type { Register } from 'claude-code'

// 1 : la cible du prompt ; 2 : un message qui commence par « ! », que le pane du lieutenant lancerait comme commande shell
// au lieu de le donner à lire à Claude.
const PROMPT = /\bherdr\b(?:\s+--machine\s+\S+)?\s+agent\s+prompt\s+["']?([^\s"']+)["']?(\s+["']?\s*!)?/
const PAR_MOTIF = /(^|[\s;&|(])(pkill|killall)\b/

export const register: Register = on => {
  // Garde-fous : un prompt herdr ne vise qu'un lieutenant et ne commence pas par « ! », et un processus ne s'arrête que
  // par son PID.
  on('tool.call', { tool: 'Bash' }, ($, e, next) => {
    const [, cible, bang] = PROMPT.exec(e.command) ?? []
    if (cible && !cible.startsWith('lt-')) {
      return {
        deny: `flotte : herdr agent prompt ne vise qu'un lieutenant (lt-…), jamais « ${cible} ». `
          + 'Pour écrire au coordinateur, utilise SendMessage.',
      }
    }
    if (bang) {
      return { deny: 'flotte : un prompt herdr ne commence jamais par « ! », qui le lance comme commande shell. Écris « La MR 1196… ».' }
    }
    if (PAR_MOTIF.test(e.command)) {
      return { deny: 'flotte : arrête un processus par son PID (kill <pid>), jamais par un motif (pkill, killall).' }
    }

    return next(e)
  }).catch(($, e, next) => next(e)) // un garde-fou cassé ne bloque pas le shell : les hooks du projet restent la barrière
}
