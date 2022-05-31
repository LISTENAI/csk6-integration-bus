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
const pwd = path.join(process.cwd(), 'node', '*')
const zephyrPwd = path.join(os.homedir(), '.listenai', 'lisa-zephyr', '*');
var str = iconv.decode(configFileStr, 'GB2312');
const result = str.replace(/###zephyrVersion###/g, zephyrVersion||'').replace(/###pwd###/g, pwd).replace(/###zephyrPwd###/g, zephyrPwd);
await  fs.writeFile('./lisaiss.iss', iconv.encode(result, 'GB2312'));
