import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Lieutenant } from '../types'

const lieutenants = atom({ plugin: 'flotte', key: 'lieutenants' } as const, [] as Lieutenant[])
const masque = atom({ plugin: 'flotte', key: 'masque' } as const, false)

const PROMPT = /\bherdr\b(?:\s+--machine\s+\S+)?\s+agent\s+prompt\s+["']?([^\s"']+)/
const PAR_MOTIF = /(^|[\s;&|(])(pkill|killall)\b/
const ETATS: Record<string, { mot: string; couleur: string }> = {
  working: { mot: 'au travail', couleur: 'success' },
  blocked: { mot: 'BLOQUÉ', couleur: 'warning' },
  idle: { mot: 'en veille', couleur: 'subtle' },
  done: { mot: 'fini', couleur: 'subtle' },
}

type Agent = { name?: string; agent_status?: string; cwd?: string; pane_id?: string }

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

  on('session.start', async ($, e, next) => {
    const started = await next(e)
    void rafraichir($)
    $.clock.every(30_000, () => void rafraichir($))

    return started
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const liste = await read($, lieutenants)
    if (e.props.hasSurvey || liste.length === 0) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    if (await read($, masque)) {
      return <Button key="flotte" label={`Flotte (${liste.length})`} onPress={() => update($, masque, () => false)} />
    }

    return (
      <Box flexDirection="column">
        {liste.map(l => {
          const etat = ETATS[l.etat] ?? { mot: l.etat, couleur: 'subtle' }

          return (
            <Text key={`${l.machine}/${l.nom}`}>
              <Text bold>{l.nom}</Text>
              <Text dimColor>{l.machine === 'local' ? '' : ` @${l.machine}`} </Text>
              <Text color={etat.couleur}>{etat.mot}</Text>
              <Text dimColor> {l.branche}</Text>
              {l.mr ? <Text> {l.mr}</Text> : null}
            </Text>
          )
        })}
        <Button key="masquer" label="Masquer" onPress={() => update($, masque, () => true)} />
      </Box>
    )
  })
}

async function json($: EngineInterface, argv: string[], cwd?: string): Promise<unknown> {
  const ran = await $.process.run(argv, cwd ? { cwd, timeoutMs: 15_000 } : { timeoutMs: 15_000 })
  if (ran.exitCode !== 0) return undefined
  try {
    return JSON.parse(ran.stdout)
  } catch {
    return undefined
  }
}

async function agents($: EngineInterface, machine: string): Promise<Agent[]> {
  const argv = machine === 'local' ? ['herdr', 'agent', 'list'] : ['herdr', '--machine', machine, 'agent', 'list']
  const out = (await json($, argv)) as { result?: { agents?: Agent[] } } | undefined

  return out?.result?.agents ?? []
}

// ponytail: une liste toutes les 30 s ; un événement herdr la rendrait instantanée si herdr en publie un un jour
async function rafraichir($: EngineInterface) {
  const local = await agents($, 'local')
  const ici = await $.env.get('HERDR_PANE_ID')
  if (local.some(a => a.pane_id === ici && a.name?.startsWith('lt-'))) return // un lieutenant n'affiche pas la flotte
  const machines = ((await json($, ['herdr', 'machine', 'list', '--json'])) as { label: string; enabled: boolean }[]
    | undefined) ?? []
  const toutes = [{ machine: 'local', liste: local }]
  for (const m of machines.filter(m => m.enabled)) toutes.push({ machine: m.label, liste: await agents($, m.label) })
  const mrs = ((await json($, ['glab', 'mr', 'list', '-F', 'json'])) as { iid: number; source_branch: string;
    detailed_merge_status?: string }[] | undefined) ?? []
  const lignes: Lieutenant[] = []
  for (const { machine, liste } of toutes) {
    for (const a of liste.filter(a => a.name?.startsWith('lt-'))) {
      const branche = machine === 'local' && a.cwd
        ? (await $.process.run(['git', '-C', a.cwd, 'branch', '--show-current'])).stdout.trim()
        : ''
      const mr = mrs.find(m => branche && m.source_branch === branche)
      lignes.push({
        nom: a.name ?? '?', machine, etat: a.agent_status ?? '?', branche,
        mr: mr ? `!${mr.iid} ${mr.detailed_merge_status ?? ''}`.trim() : '',
      })
    }
  }
  await update($, lieutenants, () => lignes)
}
