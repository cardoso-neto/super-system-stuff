import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, readFile, readdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const directory = dirname(fileURLToPath(import.meta.url));
const fixtures = join(directory, 'fixtures/cask-relaunch');
const updater = resolve(directory, '../bin/autoupdate.sh');

for (const name of (await readdir(fixtures)).filter(name => name.endsWith('.input.json'))) {
  test(name, async () => {
    const input = JSON.parse(await readFile(join(fixtures, name), 'utf8'));
    const expected = JSON.parse(await readFile(join(fixtures, name.replace('.input.json', '.expected.json')), 'utf8'));
    const temporary = await mkdtemp(join(tmpdir(), 'updater-cask-relaunch-'));
    try {
      const child = spawnSync('/bin/bash', [join(fixtures, 'action.sh'), updater, temporary,
        String(input.upgradeExit), String(input.running), String(input.relaunchExit), String(input.laterExit)],
      { encoding: 'utf8', timeout: 10000 });
      console.log(child.stdout + child.stderr);
      assert.ifError(child.error);
      const result = JSON.parse(await readFile(join(temporary, 'result.json'), 'utf8'));
      const commands = (await readFile(join(temporary, 'commands'), 'utf8')).trim().split('\n');
      const failures = await readFile(join(temporary, 'failures'), 'utf8');
      assert.deepEqual({ ...result, exit: child.status, commands,
        failureExits: [...failures.matchAll(/\(exit (\d+)\)/g)].map(match => Number(match[1])) }, expected);
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  });
}
