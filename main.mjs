#!/usr/bin/env zx

let manifest = await fs.readFile('./manifest.json');
manifest = JSON.parse(manifest.toString());

// for (let i in manifest) {
//   const plugin = manifest[i];
  // await lpmInstall(plugin.name, plugin.version);
await $`lisa install @lisa-plugin/zephyr@1.6.2-beta.7 -g  --registry=https://registry-lpm.listenai.com `
await $`lisa install @lisa-plugin/term@1.1.0 -g  --registry=https://registry-lpm.listenai.com `
// }
await $`lisa zep use-env csk6`

// async function lpmInstall(name, version) {
//   await $`lisa install ${name}@${version} -g  --registry=https://registry-lpm.listenai.com `
// }
