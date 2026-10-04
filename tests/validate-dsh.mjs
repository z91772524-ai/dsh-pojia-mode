// Read-only composition validation against an installed Electron/ASAR runtime.
// ELECTRON_RUN_AS_NODE=1 "DeepSeek Harness.exe" --expose-internals tests/validate-dsh.mjs <install-dir> <profile-dir>
// --boot additionally mounts a copied profile in an isolated temporary DSH_HOME.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { mkdtempSync, mkdirSync, copyFileSync, writeFileSync, appendFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';

const [installation, profileDir, bootFlag] = process.argv.slice(2);
const anchor = join(installation, 'resources', 'app.asar', 'dsh', 'node_modules', '@deepseek-ai', 'dsh', 'package.json');
const requireRuntime = createRequire(anchor);
const importRuntime = name => import(pathToFileURL(requireRuntime.resolve(name)).href);
const { loadProfileDirectory, composeEntries, loadLayeredEnv } = await importRuntime('@deepseek-ai/dsh-app-boot');
const { entryListProblem } = await importRuntime('@deepseek-ai/dsh-agent-preset-registry');
const profile = loadProfileDirectory('dsh', profileDir, anchor);
assert.equal(profile.skippedBundles.length, 0, JSON.stringify(profile.skippedBundles));
const warnings = [];
const entries = composeEntries([...profile.layers.map(layer => layer.patches), profile.patches], message => warnings.push(message));
assert.deepEqual(warnings, []);
const presets = entries.filter(row => row.name === '@deepseek-ai/dsh-agent-preset');
const custom = presets.filter(row => row.config.id === 'pj-mode');
assert.equal(custom.length, 1, 'Expected exactly one registered pj-mode');
assert.equal(custom[0].config.name, '\u7834\u7532\u6a21\u5f0f', 'Preset label encoding is wrong');
assert.equal(entryListProblem(custom[0].config.plugins), undefined);
function verifyPackages(rows) {
  for (const row of rows) {
    if (row.name !== 'cordis:group') requireRuntime.resolve(row.name);
    if (row.name === 'cordis:group') verifyPackages(row.config);
  }
}
verifyPackages(custom[0].config.plugins);
console.log(JSON.stringify({ validation: 'passed', presets: presets.map(row => row.config.id) }));

if (bootFlag === '--boot') {
  const testHome = mkdtempSync(join(tmpdir(), 'dsh-unlock-runtime-'));
  const isolatedProfile = join(testHome, 'profiles', 'desktop');
  const timeout = setTimeout(() => { console.error('Isolated profile boot timed out'); process.exit(1); }, 45000);
  try {
    mkdirSync(isolatedProfile, { recursive: true });
    for (const file of ['package.json', 'cordis.patch.yml']) copyFileSync(join(profileDir, file), join(isolatedProfile, file));
    // Product telemetry normally receives app-version metadata from Electron's shell.
    appendFileSync(join(isolatedProfile, 'cordis.patch.yml'), '\n- id: desktop-product-telemetry\n  disabled: true\n- id: product-analytics\n  disabled: true\n');
    writeFileSync(join(isolatedProfile, 'cordis.yml'), '[]\n');
    process.env.DSH_HOME = testHome;
    process.env.DSH_TELEMETRY_DISABLED = '1';
    const { runProfile } = await importRuntime('@deepseek-ai/dsh/profile-boot');
    const app = await runProfile({
      environment: loadLayeredEnv('dsh', testHome), profile: 'desktop',
      resolvedProfile: { profile: loadProfileDirectory('dsh', isolatedProfile, anchor), installAnchor: anchor },
      patchFiles: [], args: ['--no-open', '--port', '0'],
    });
    try {
      const rows = await app.ctx.agentPresets.list();
      const row = rows.find(row => row.id === 'pj-mode');
      console.log(JSON.stringify({ runtimePreset: row }).replace(/[^\x00-\x7f]/g, char => '\\u' + char.charCodeAt(0).toString(16).padStart(4, '0')));
      assert.ok(row, 'Runtime did not register pj-mode');
      assert.ok(!row.broken, `Runtime preset failed: ${row.broken}`);
    } finally {
      await app.ctx.fiber.dispose();
    }
  } finally {
    clearTimeout(timeout);
    rmSync(testHome, { recursive: true, force: true });
  }
}
process.exit(0);
