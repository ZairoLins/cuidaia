// Testa firestore.rules no emulador local, pela API REST, com tokens não
// assinados (aceitos só pelo emulador). Não toca no projeto real.
// Uso (precisa de Node 18+, Java e Firebase CLI):
//   firebase emulators:exec --only firestore --project demo-cuidaia "node tool/testar_regras.mjs"
// Rode sempre antes de `firebase deploy --only firestore:rules`.
const projeto = process.env.GCLOUD_PROJECT || 'demo-cuidaia';
const host = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const base = `http://${host}/v1/projects/${projeto}/databases/(default)/documents`;
const nomeDoc = (caminho) => `projects/${projeto}/databases/(default)/documents/${caminho}`;

const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
function token(uid) {
  const agora = Math.floor(Date.now() / 1000);
  return `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    sub: uid,
    user_id: uid,
    iss: `https://securetoken.google.com/${projeto}`,
    aud: projeto,
    iat: agora,
    exp: agora + 3600,
    email: `${uid}@exemplo.com`,
    firebase: { sign_in_provider: 'password', identities: {} },
  })}.`;
}
const cab = (uid) => ({ 'Content-Type': 'application/json', ...(uid ? { Authorization: `Bearer ${token(uid)}` } : {}) });

const s = (v) => ({ stringValue: v });
const perfil = (extra = {}) => ({ nome: s('Maria Silva'), apelido: s('Maria'), email: s('ana@exemplo.com'), foto: { nullValue: null }, ...extra });

async function commit(uid, write) {
  const r = await fetch(`${base}:commit`, { method: 'POST', headers: cab(uid), body: JSON.stringify({ writes: [write] }) });
  return r.status;
}
const criar = (uid, caminho, campos, { carimbo = true } = {}) =>
  commit(uid, {
    update: { name: nomeDoc(caminho), fields: campos },
    ...(carimbo ? { updateTransforms: [{ fieldPath: 'criadoEm', setToServerValue: 'REQUEST_TIME' }] } : {}),
  });
// Equivale ao set(..., merge: true) e ao update() do app: só os campos da máscara mudam.
const mesclar = (uid, caminho, campos) =>
  commit(uid, { update: { name: nomeDoc(caminho), fields: campos }, updateMask: { fieldPaths: Object.keys(campos) } });
const ler = async (uid, caminho) => (await fetch(`${base}/${caminho}`, { headers: cab(uid) })).status;
const apagar = (uid, caminho) => commit(uid, { delete: nomeDoc(caminho) });

let falhas = 0;
async function caso(descricao, esperado, acao) {
  const status = await acao();
  const permitido = status === 200;
  const ok = permitido === (esperado === 'permite');
  if (!ok) falhas++;
  console.log(`${ok ? 'OK   ' : 'FALHA'} ${descricao} (esperado: ${esperado}, HTTP ${status})`);
}

const bytes = (n) => ({ bytesValue: Buffer.alloc(n, 1).toString('base64') });

await caso('cadastro cria o próprio perfil com a data do servidor', 'permite', () => criar('ana', 'usuarios/ana', perfil()));
await caso('dona lê o próprio perfil', 'permite', () => ler('ana', 'usuarios/ana'));
await caso('outra pessoa não lê o perfil', 'nega', () => ler('bia', 'usuarios/ana'));
await caso('sem login não lê o perfil', 'nega', () => ler(null, 'usuarios/ana'));
await caso('salvar perfil (merge de nome, apelido, e-mail e foto)', 'permite', () =>
  mesclar('ana', 'usuarios/ana', perfil({ nome: s('Maria Souza'), foto: bytes(1000) })));
await caso('atualizar só o e-mail (troca confirmada)', 'permite', () => mesclar('ana', 'usuarios/ana', { email: s('nova@exemplo.com') }));
await caso('remover a foto (foto nula)', 'permite', () => mesclar('ana', 'usuarios/ana', { foto: { nullValue: null } }));
await caso('alterar a data de criação', 'nega', () =>
  mesclar('ana', 'usuarios/ana', { criadoEm: { timestampValue: '2020-01-01T00:00:00Z' } }));
await caso('outra pessoa não altera o perfil', 'nega', () => mesclar('bia', 'usuarios/ana', { nome: s('Invasora') }));
await caso('nome com 121 caracteres', 'nega', () => mesclar('ana', 'usuarios/ana', { nome: s('a'.repeat(121)) }));
await caso('nome com 120 caracteres', 'permite', () => mesclar('ana', 'usuarios/ana', { nome: s('a'.repeat(120)) }));
await caso('apelido com 61 caracteres', 'nega', () => mesclar('ana', 'usuarios/ana', { apelido: s('a'.repeat(61)) }));
await caso('campo não previsto', 'nega', () => mesclar('ana', 'usuarios/ana', { admin: { booleanValue: true } }));
await caso('foto acima de 300 KB', 'nega', () => mesclar('ana', 'usuarios/ana', { foto: bytes(307201) }));
await caso('foto com exatamente 300 KB', 'permite', () => mesclar('ana', 'usuarios/ana', { foto: bytes(307200) }));
await caso('foto que não é imagem em bytes (texto)', 'nega', () => mesclar('ana', 'usuarios/ana', { foto: s('x') }));
await caso('criar perfil com data de criação escolhida pelo cliente', 'nega', () =>
  criar('bia', 'usuarios/bia', perfil({ criadoEm: { timestampValue: '2020-01-01T00:00:00Z' } }), { carimbo: false }));
await caso('criar perfil de outra pessoa', 'nega', () => criar('bia', 'usuarios/carla', perfil()));
await caso('primeiro login com Google cria o perfil (merge + data do servidor)', 'permite', () =>
  commit('bia', {
    update: { name: nomeDoc('usuarios/bia'), fields: perfil({ nome: s('') , apelido: s('') }) },
    updateMask: { fieldPaths: ['nome', 'apelido', 'email', 'foto'] },
    updateTransforms: [{ fieldPath: 'criadoEm', setToServerValue: 'REQUEST_TIME' }],
  }));
await caso('outra coleção é negada', 'nega', () => criar('ana', 'outra/x', { a: s('b') }, { carimbo: false }));
await caso('outra pessoa não apaga o perfil', 'nega', () => apagar('bia', 'usuarios/ana'));
await caso('dona apaga o próprio perfil', 'permite', () => apagar('ana', 'usuarios/ana'));

console.log(falhas === 0 ? '\nTodas as regras se comportaram como esperado.' : `\n${falhas} caso(s) fora do esperado.`);
process.exit(falhas === 0 ? 0 : 1);
