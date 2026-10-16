import { expect, test } from 'claude-code/testing'

// Le hook du test tient lieu de shell : ce qui l'atteint est passé par les garde-fous de la flotte.
test('un prompt herdr ne vise qu’un lieutenant, et pkill par motif est refusé', async ($, on) => {
  const passes: string[] = []
  on('tool.call', { tool: 'Bash' }, ($, e) => (passes.push(e.command), { result: { stdout: 'ok', stderr: '', interrupted: false } } as never))

  const versCoordinateur = await $.tool.call({ tool: 'Bash', command: 'herdr agent prompt w1:p1 "fini"' })
  expect(JSON.stringify(versCoordinateur)).toMatch(/SendMessage/)

  const parMotif = await $.tool.call({ tool: 'Bash', command: 'pkill -f vite' })
  expect(JSON.stringify(parMotif)).toMatch(/PID/)

  await $.tool.call({ tool: 'Bash', command: 'herdr agent prompt lt-pot "go #769"' })
  await $.tool.call({ tool: 'Bash', command: 'herdr --machine portable agent prompt lt-cartes "go"' })
  await $.tool.call({ tool: 'Bash', command: 'kill 4242' })
  expect(passes).toEqual(['herdr agent prompt lt-pot "go #769"', 'herdr --machine portable agent prompt lt-cartes "go"',
    'kill 4242'])
})
