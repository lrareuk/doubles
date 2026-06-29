/**
 * Run the engine for one world from the CLI (brief §14 step 3).
 *   pnpm --filter @doubles/api run-episode <worldId>
 *
 * Loads env from the repo-root .env (no dotenv dependency). Works with
 * AI_PROVIDER=mock and no Anthropic key.
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

function loadEnv(): void {
  const here = dirname(fileURLToPath(import.meta.url));
  const envPath = resolve(here, '../../../.env');
  try {
    const text = readFileSync(envPath, 'utf8');
    for (const line of text.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq === -1) continue;
      const key = trimmed.slice(0, eq).trim();
      let value = trimmed.slice(eq + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      if (!(key in process.env)) process.env[key] = value;
    }
  } catch {
    // No .env — rely on the ambient environment.
  }
}

async function main(): Promise<void> {
  loadEnv();
  const worldId = process.argv[2];
  if (!worldId) {
    console.error('usage: run-episode <worldId>');
    process.exit(1);
  }
  // Imported after env is loaded so getEnv() sees the values.
  const { runEpisodeForWorld } = await import('../lib/engineJob.js');
  const result = await runEpisodeForWorld(worldId);
  console.log(JSON.stringify(result, null, 2));
  if (result.status === 'failed') process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
