import type { Register } from 'claude-code'

const PROMPT = /\bherdr\b(?:\s+--machine\s+\S+)?\s+agent\s+prompt\s+["']?([^\s"']+)/
const PAR_MOTIF = /(^|[\s;&|(])(pkill|killall)\b/

export const register: Register = on => {
  // Garde-fous : un prompt herdr ne vise qu'un lieutenant, et un processus ne s'arrête que par son PID.
  on('tool.call', { tool: 'Bash' }, ($, e, next) => {
    const cible = PROMPT.exec(e.command)?.[1]
    if (cible && !cible.startsWith('lt-')) {
      return {
        deny: `flotte : herdr agent prompt ne vise qu'un lieutenant (lt-…), jamais « ${cible} ». `
          + 'Pour écrire au coordinateur, utilise SendMessage.',
      }
    }
    if (PAR_MOTIF.test(e.command)) {
      return { deny: 'flotte : arrête un processus par son PID (kill <pid>), jamais par un motif (pkill, killall).' }
    }

    return next(e)
  }).catch(($, e, next) => next(e)) // un garde-fou cassé ne bloque pas le shell : les hooks du projet restent la barrière
}
