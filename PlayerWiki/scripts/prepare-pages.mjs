import { copyFile, mkdir, rename, rmdir, writeFile } from 'node:fs/promises';
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
await mkdir(path.join(splashReferenceRoot, 'src'), { recursive: true });
await mkdir(path.join(splashReferenceRoot, 'fonts'), { recursive: true });
for (const file of [
  'world-splash-five-layer-inventory-v1.html',
  'world-splash-five-layer-inventory-v1.css',
]) {
  await copyFile(path.resolve('../AssetLab', file), path.join(splashReferenceRoot, file));
}
for (const file of [
  'world-splash-five-layer-inventory-v1.js',
  'world-splash-five-layer-inventory-v1-app.js',
]) {
  await copyFile(path.resolve('../AssetLab/src', file), path.join(splashReferenceRoot, 'src', file));
}
for (const file of ['Tiny5-Regular.ttf', 'Jersey10-Regular.ttf']) {
  await copyFile(path.resolve('../AssetLab/fonts', file), path.join(splashReferenceRoot, 'fonts', file));
}

console.log(`Prepared static wiki artifact for /${basePath}.`);
