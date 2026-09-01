import { rename, rmdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';

const basePath = (process.env.NEXT_PUBLIC_BASE_PATH ?? '').replace(/^\/+|\/+$/g, '');
if (!basePath) {
  throw new Error('NEXT_PUBLIC_BASE_PATH is required when preparing the GitHub Pages artifact.');
}

const clientRoot = path.resolve('dist/client');
const prefixedAssetRoot = path.join(clientRoot, basePath);
await rename(path.join(prefixedAssetRoot, '_next'), path.join(clientRoot, '_next'));
await rmdir(prefixedAssetRoot);
await writeFile(path.join(clientRoot, '.nojekyll'), '');

console.log(`Prepared static wiki artifact for /${basePath}.`);
