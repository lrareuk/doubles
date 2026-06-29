import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

/** @type {import('next').NextConfig} */
const nextConfig = {
  // The engine + db packages are plain TS workspace packages; transpile them.
  transpilePackages: ['@doubles/shared', '@doubles/engine', '@doubles/db'],
  // Pin the monorepo root so Next doesn't latch onto a stray lockfile elsewhere.
  outputFileTracingRoot: repoRoot,
};

export default nextConfig;
