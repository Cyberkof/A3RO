import { build } from 'esbuild';
import { resolve } from 'node:path';

const pkg = process.argv[2];
if (!pkg) {
  console.error('Usage: tsx esbuild.config.ts <package-name>');
  process.exit(1);
}

await build({
  entryPoints: [resolve(`packages/${pkg}/src/index.ts`)],
  bundle: true,
  platform: 'node',
  target: 'node20',
  format: 'esm',
  outfile: resolve(`packages/${pkg}/dist/index.js`),
  external: ['node:*'],
  sourcemap: true,
  minify: false,
});

console.log(`Built packages/${pkg}/dist/index.js`);
