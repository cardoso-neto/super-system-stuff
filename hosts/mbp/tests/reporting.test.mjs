import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const directory = dirname(fileURLToPath(import.meta.url));
const fixtures = join(directory, 'fixtures');
const updater = resolve(directory, '../bin/autoupdate.sh');
const reporter = resolve(directory, '../../../shared/t3-findings/report.sh');

for (const name of (await readdir(fixtures)).filter(name => name.endsWith('.expected.json'))) {
  test(name, { timeout: 15000 }, async () => {
    const expected = JSON.parse(await readFile(join(fixtures, name), 'utf8'));
    const temporary = await mkdtemp(join(tmpdir(), 'updater-reporting-'));
    const requests = [];
    const server = createServer(async (request, response) => {
      const chunks = [];
      for await (const chunk of request) chunks.push(chunk);
      requests.push(JSON.parse(Buffer.concat(chunks).toString()));
      response.writeHead(202).end();
    });
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    try {
      const config = join(temporary, 'webhook.json');
      await writeFile(config, JSON.stringify({ url: `http://127.0.0.1:${server.address().port}/hook` }));
      const fixture = join(fixtures, name.replace('.expected.json', '.action.sh'));
      const child = spawn('/bin/bash', [fixture, updater, temporary, reporter], {
        env: { ...process.env, T3_FINDINGS_CONFIG: config, T3_FINDINGS_STATE_DIR: join(temporary, 'queue') },
      });
      const output = [];
      child.stdout.on('data', chunk => output.push(chunk));
      child.stderr.on('data', chunk => output.push(chunk));
      const timeout = setTimeout(() => child.kill('SIGKILL'), 10000);
      let status;
      try {
        status = await new Promise((resolve, reject) => {
          child.once('error', reject);
          child.once('close', resolve);
        });
      } finally {
        clearTimeout(timeout);
      }
      console.log(Buffer.concat(output).toString());
      assert.equal(status, expected.exit);
      assert.equal(requests.length, 1);
      for (const text of expected.contains) assert.ok(requests[0].error.includes(text), text);
      for (const text of expected.excludes) assert.ok(!requests[0].error.includes(text), text);
      assert.deepEqual(await readdir(join(temporary, 'queue')), []);
      assert.ok(!(await readdir(temporary)).some(name => name.startsWith('run.')));
    } finally {
      await new Promise(resolve => server.close(resolve));
      await rm(temporary, { recursive: true, force: true });
    }
  });
}
