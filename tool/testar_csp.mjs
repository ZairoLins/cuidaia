// Serve build/web com os cabeçalhos de firebase.json, abre a página num Chrome
// sem janela e lista as violações de Content-Security-Policy e se o Flutter
// desenhou a tela. Não cobre o login com o Google nem o uso depois do login:
// esses precisam de teste manual.
// Uso (Node 22+ e Chrome; outro caminho do Chrome: variável CHROME):
//   flutter build web --release
//   node tool/testar_csp.mjs .                    (app)
//   node tool/testar_csp.mjs . privacidade.html   (página de privacidade; "Flutter desenhou" fica false)
import { spawn } from 'node:child_process';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Servidor local de build/web que envia os cabeçalhos do bloco "**" de
// firebase.json (o emulador do Hosting não envia cabeçalhos no Windows).
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { extname, resolve } from 'node:path';
const raiz = resolve(process.argv[2] || '.');
const cabecalhos = JSON.parse(readFileSync(join(raiz, 'firebase.json'), 'utf8')).hosting.headers.find((h) => h.source === '**').headers;
const tipos = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf', '.css': 'text/css' };
const servidor = createServer((req, res) => {
  let caminho = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (caminho.endsWith('/')) caminho += 'index.html';
  const arquivo = join(raiz, 'build', 'web', caminho);
  for (const c of cabecalhos) res.setHeader(c.key, c.value);
  if (!arquivo.startsWith(join(raiz, 'build', 'web')) || !existsSync(arquivo) || !statSync(arquivo).isFile()) { res.statusCode = 404; return res.end('404'); }
  res.setHeader('Content-Type', tipos[extname(arquivo)] || 'application/octet-stream');
  res.end(readFileSync(arquivo));
});
await new Promise((r) => servidor.listen(5055, '127.0.0.1', r));

const url = 'http://127.0.0.1:5055/' + (process.argv[3] || '');
const espera = Number(process.argv[4] || 25000);
const porta = 9333;
const chrome = process.env.CHROME || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const perfil = mkdtempSync(join(tmpdir(), 'csp-chrome-'));
const proc = spawn(chrome, ['--headless=new', `--remote-debugging-port=${porta}`, `--user-data-dir=${perfil}`, '--no-first-run', 'about:blank'], { stdio: 'ignore' });

const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
async function alvo() {
  for (let i = 0; i < 40; i++) {
    try {
      const abas = await (await fetch(`http://127.0.0.1:${porta}/json`)).json();
      const aba = abas.find((a) => a.type === 'page');
      if (aba) return aba.webSocketDebuggerUrl;
    } catch {}
    await dormir(250);
  }
  throw new Error('Chrome não respondeu');
}

let codigo = 1;
try {
  const ws = new WebSocket(await alvo());
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  let id = 0;
  const pendentes = new Map();
  const registros = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pendentes.has(d.id)) { pendentes.get(d.id)(d.result); pendentes.delete(d.id); }
    if (d.method === 'Log.entryAdded' && ['error', 'warning'].includes(d.params.entry.level)) registros.push(`[${d.params.entry.source}] ${d.params.entry.text} ${d.params.entry.url || ''}`);
    if (d.method === 'Runtime.exceptionThrown') registros.push(`[exceção] ${d.params.exceptionDetails.exception?.description || d.params.exceptionDetails.text}`);
    if (d.method === 'Runtime.consoleAPICalled' && d.params.type === 'error') registros.push(`[console] ${d.params.args.map((a) => a.value ?? a.description).join(' ')}`);
  };
  const cmd = (method, params = {}) => new Promise((r) => { pendentes.set(++id, r); ws.send(JSON.stringify({ id, method, params })); });
  await cmd('Log.enable');
  await cmd('Runtime.enable');
  await cmd('Page.enable');
  await cmd('Page.addScriptToEvaluateOnNewDocument', {
    source: `window.__csp = []; document.addEventListener('securitypolicyviolation', (e) => window.__csp.push(e.effectiveDirective + ' | ' + (e.blockedURI || 'inline') + ' | ' + (e.sourceFile || '') + ':' + e.lineNumber + ' | ' + (e.sample || '')));`,
  });
  await cmd('Page.navigate', { url });
  await dormir(espera);
  const r = await cmd('Runtime.evaluate', {
    returnByValue: true,
    expression: `JSON.stringify({ csp: window.__csp, carregandoSumiu: !document.getElementById('carregando'), flutter: !!document.querySelector('flutter-view, flt-glass-pane'), scripts: [...document.scripts].map(s => s.src || ('inline:' + s.textContent.slice(0, 80))), frames: [...document.querySelectorAll('iframe')].map(f => f.src) })`,
  });
  const estado = JSON.parse(r.result.value);
  const cabecalho = (await fetch(url)).headers.get('content-security-policy');
  console.log('CSP enviada:', cabecalho);
  console.log('Flutter desenhou a tela:', estado.carregandoSumiu && estado.flutter);
  console.log('Scripts na página:'); estado.scripts.forEach((s) => console.log('  ', s));
  console.log('Frames na página:'); estado.frames.forEach((s) => console.log('  ', s));
  const unicas = [...new Set(estado.csp)];
  console.log(`Violações de CSP (${unicas.length}):`); unicas.forEach((v) => console.log('  ', v));
  console.log(`Erros e avisos do console (${registros.length}):`); [...new Set(registros)].slice(0, 40).forEach((v) => console.log('  ', v.slice(0, 400)));
  codigo = unicas.length === 0 && estado.carregandoSumiu && estado.flutter ? 0 : 1;
  ws.close();
} finally {
  proc.kill();
  servidor.close();
}
process.exitCode = codigo;
setTimeout(() => process.exit(codigo), 500).unref();
