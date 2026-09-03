import { mkdir, rename, rmdir, writeFile } from 'node:fs/promises';
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

const splashReferenceRoot = path.join(clientRoot, 'reference-assets');
await mkdir(splashReferenceRoot, { recursive: true });
await writeFile(
  path.join(splashReferenceRoot, 'world-splash-five-layer-inventory-v1.html'),
  '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0; url=../references/world-splash-assets.html"><title>World Splash Asset Inventory</title></head><body><p><a href="../references/world-splash-assets.html">Open the World Splash Asset Inventory</a></p></body></html>',
);

console.log(`Prepared static wiki artifact for /${basePath}.`);
