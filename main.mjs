#!/usr/bin/env zx

let manifest = await fs.readFile('./manifest.json');
manifest = JSON.parse(manifest.toString());

for (let i in manifest) {
  const plugin = manifest[i];
  await lpmInstall(plugin.name, plugin.version);
}

await $`lisa zep use-env csk6`

async function lpmInstall(name, version) {
  const command = `lisa install ${name}@${version} -g  --registry=https://registry-lpm.listenai.com `
  await $`${command}`
}
