#!/usr/bin/env zx

let manifest = await fs.readFile('./manifest.json');
manifest = JSON.parse(manifest.toString());

await $`lisa install @lisa-plugin/zephyr@2.0.0 -g  --registry=https://registry-lpm.listenai.com `
await $`lisa install @lisa-plugin/term@1.1.0 -g  --registry=https://registry-lpm.listenai.com `
await $`lisa zep use-env --clear`
await $`lisa zep use-env csk6 `