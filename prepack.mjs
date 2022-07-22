#!/usr/bin/env zx
import iconv from 'iconv-lite';
const configFileStr = await fs.readFile('./lisaiss.iss');
let manifest = await fs.readFile('./manifest.json');
manifest = JSON.parse(manifest.toString());
let zephyrVersion; 
for (let i in manifest) {
    const plugin = manifest[i];
    console.log(plugin)
    if (plugin.name === '@lisa-plugin/zephyr') {
      zephyrVersion = plugin.version
  }
}

await fs.remove(path.join(os.homedir(), '.listenai', 'lisa-zephyr', 'venv', 'Lib'));
await fs.remove(path.join(os.homedir(), '.listenai', 'lisa-zephyr', 'envs'));

const pwd = path.join(process.cwd(), 'node', '*')
const zephyrPwd = path.join(os.homedir(), '.listenai', 'lisa-zephyr', '*');
var str = iconv.decode(configFileStr, 'utf-8');
const result = str.replace(/###zephyrVersion###/g, zephyrVersion||'').replace(/###pwd###/g, pwd).replace(/###zephyrPwd###/g, zephyrPwd);
await  fs.writeFile('./lisaiss.iss', iconv.encode(result, 'utf-8'));
