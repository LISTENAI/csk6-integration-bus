#!/usr/bin/env zx
import iconv from 'iconv-lite';
const configFileStr = await fs.readFile('./lisaiss.iss');
const pwd = path.join(process.cwd(), 'node', '*')
const zephyrPwd = path.join(os.homedir(), '.listenai', 'lisa-zephyr', '*');
var str = iconv.decode(configFileStr, 'GB2312');
const result = str.replace(/###pwd###/g, pwd).replace(/###zephyrPwd###/g, zephyrPwd);
await  fs.writeFile('./lisaiss.iss', iconv.encode(result, 'GB2312'));
