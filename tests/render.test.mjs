import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
for (const source of ['flowchart LR\n A-->B', 'sequenceDiagram\n Alice->>Bob: Hello']) {
  test(source.split('\n')[0], () => {
    const dir = mkdtempSync(join(tmpdir(), 'pele-test-'));
    try {
      const path = join(dir, 'diagram.png');
      const result = spawnSync(process.execPath, ['scripts/render.mjs', path], { input: source, encoding: 'utf8' });
      assert.equal(result.status, 0, result.stderr);
      assert.equal(readFileSync(path).subarray(1, 4).toString(), 'PNG');
    } finally { rmSync(dir, { recursive: true }); }
  });
}
test('invalid input reports failure', () => {
  const result = spawnSync(process.execPath, ['scripts/render.mjs', '/tmp/pele-invalid.png'], { input: 'not a diagram', encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.ok(result.stderr.length);
});
test('editor palette changes rendered pixels', () => {
  const dir = mkdtempSync(join(tmpdir(), 'pele-theme-'));
  try {
    const outputs = ['#ffffff', '#161821'].map((bg, i) => {
      const path = join(dir, `${i}.png`);
      const palette = { '--pele-bg': bg, '--pele-fg': i ? '#c6c8d1' : '#222222', '--pele-surface': bg };
      const result = spawnSync(process.execPath, ['scripts/render.mjs', path, JSON.stringify(palette)], { input: 'flowchart LR\n A-->B', encoding: 'utf8' });
      assert.equal(result.status, 0, result.stderr);
      return readFileSync(path);
    });
    assert.notDeepEqual(outputs[0], outputs[1]);
  } finally { rmSync(dir, { recursive: true }); }
});
