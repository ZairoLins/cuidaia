# Publicação na Google Play: o que está pronto e o que falta

O app **não foi publicado**. Este roteiro deixa tudo pronto para quando (e se) for.

## 1. Já pronto no projeto

| Item | Onde |
|---|---|
| Ícone do app (Android adaptativo, iOS, web) | `assets/icone/`, gerado com `dart run flutter_launcher_icons` |
| Ícone da notificação (silhueta branca) | `android/app/src/main/res/drawable-*/ic_notificacao.png` |
| Chave de upload (release) | `android/app/upload-keystore.jks` + `android/key.properties` (**fora do git**) |
| Pacote para a loja | `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab` |
| APK para avaliadores | `flutter build apk --release --split-per-abi` → use o `app-arm64-v8a-release.apk` |
| Política de privacidade e exclusão de conta (páginas públicas) | `web/privacidade.html` (seção `#excluir-conta`), publicada junto do app web |
| Backup desligado e só HTTPS no Android | `AndroidManifest.xml` e `res/xml/data_extraction_rules.xml` |
| Cabeçalhos de segurança da web, com *Content-Security-Policy* | `firebase.json` + `tool/testar_csp.mjs` (valem a partir do próximo `firebase deploy --only hosting`; antes, teste o login com o Google na web) |
| Release só com a chave de upload | `android/app/build.gradle.kts` recusa o build de release sem `android/key.properties` |
| Confirmação de e-mail obrigatória | `lib/screens/confirmar_email_screen.dart` |
| Regras do banco testadas | `firestore.rules` + `tool/testar_regras.mjs` (valem a partir do próximo `firebase deploy --only firestore:rules`) |

> **Faça backup da chave agora.** Copie `android/app/upload-keystore.jks` e
> `android/key.properties` para um lugar seguro fora do computador (pendrive,
> gerenciador de senhas). Sem eles não dá para enviar atualizações com a mesma
> chave. Com o Play App Signing, uma chave de upload perdida pode ser trocada
> pelo suporte do Google, mas leva dias.

Identificação: pacote `br.com.cuidaia.app`, versão `1.0.0+1` (em `pubspec.yaml`;
suba o número depois do `+` a cada envio).

## 2. Firebase (console)

1. **SHA da chave de release** em *Configurações do projeto > Seus apps > Android*:
   - SHA-1: `77:D1:36:D2:67:50:D2:52:66:4E:52:90:99:40:BA:0E:D1:77:E5:68`
   - SHA-256: `6B:99:FB:1F:4A:59:A3:67:00:C4:3B:10:EB:D9:4D:F3:69:31:20:15:C4:4D:E9:4D:86:7A:42:DF:31:0A:64:01`

   Sem isso, o login com Google falha no APK de release. Depois de baixar o
   `google-services.json` novo, substitua o de `android/app/`.
2. **Depois do primeiro envio à Play**: copie os SHA-1/SHA-256 da *chave de
   assinatura do app* (Play Console > Integridade do app) e cadastre também.
   É com essa chave que o Google assina o app que as pessoas baixam.
3. **App Check > Apps > Android > Play Integrity**: registre com o SHA-256 da
   chave de assinatura da Play. Sem isso, o assistente responde 403 no app da loja.
4. **App Check para Authentication e Firestore**: deixe em "Não aplicado" e
   acompanhe as métricas. Só clique em **Aplicar** quando quase todo o tráfego
   aparecer como verificado.
5. **Páginas públicas**: `firebase deploy --only hosting`. Os endereços ficam:
   - `https://cuidaia-41f74.web.app/privacidade.html`
   - `https://cuidaia-41f74.web.app/privacidade.html#excluir-conta`

## 3. Play Console

Conta de desenvolvedor: taxa única de US$ 25. Contas pessoais novas precisam
de um **teste fechado com 12 testadores por 14 dias** antes de liberar a
produção. Dá para usar colegas e a banca como testadores.

### Ficha da loja

- **Nome:** CuidaIA
- **Descrição curta** (até 80 caracteres):
  `Entenda o SUS e saiba onde ser atendido, em linguagem simples.`
- **Descrição completa:**

  ```
  O CuidaIA ajuda você a entender como funciona o SUS e a encontrar o lugar
  certo para cada situação: UBS, UPA, hospital, CAPS ou SAMU 192.

  • Assistente com inteligência artificial que responde em linguagem simples,
    sempre com a fonte oficial do Ministério da Saúde.
  • "Onde devo ser atendido?": perguntas rápidas que indicam o serviço mais
    adequado.
  • Conteúdos sobre a Rede de Atenção à Saúde: atenção primária, secundária,
    terciária e urgência.
  • Acessibilidade: texto maior, alto contraste, fonte facilitada e leitura em
    voz alta.
  • Dica da semana e lembretes de leitura (opcionais).

  Importante: o CuidaIA orienta, mas não faz diagnóstico e não substitui o
  atendimento de um profissional de saúde. Em emergência, ligue 192.

  Projeto acadêmico (trabalho de conclusão de curso). Não pedimos dados de
  saúde e não exibimos anúncios.
  ```
- **Categoria:** Medicina. A Play pede o formulário de **apps de saúde**.
  Declare "informação e educação em saúde", sem diagnóstico e sem dispositivo médico.
- **Contato:** zairolins15@gmail.com
- **Política de privacidade:** o endereço do item 2.5

### Imagens

| Imagem | Tamanho | Situação |
|---|---|---|
| Ícone | 512 × 512 PNG | `web/icons/Icon-512.png` |
| Gráfico de destaque | 1024 × 500 | **falta** |
| Capturas de celular | mínimo 2, de 1080 × 1920 a 1080 × 2400 | **falta**: tire no próprio celular (Início, Assistente, Aprenda, Artigo) |

### Questionários

- **Anúncios:** não.
- **Público-alvo:** 18 anos ou mais. Isso evita as regras da Família para
  crianças, que não combinam com um chat de IA.
- **Classificação de conteúdo:** app de referência/educação. Sem violência,
  sem conteúdo sexual, sem compras. Marque que há conteúdo gerado por IA.
- **Acesso ao app:** o login é obrigatório. Crie uma conta de teste
  (e-mail e senha) só para a revisão e informe-a nesse formulário.
- **App governamental:** não. O app fala do SUS, mas não é do governo. Por isso
  ele também não usa marcas oficiais.

### Segurança dos dados

| Dado | Coletado? | Compartilhado? | Finalidade | Obrigatório? |
|---|---|---|---|---|
| Nome | Sim | Não | Gerenciamento da conta | Sim |
| E-mail | Sim | Não | Gerenciamento da conta | Sim |
| Fotos (foto de perfil) | Sim | Não | Personalização | Não |
| Outras mensagens no app (perguntas ao assistente) | Sim | Sim (Google, pelo Gemini no plano gratuito) | Funcionalidade do app | Sim, para usar o assistente |
| IDs do dispositivo (App Check / Firebase) | Sim | Não | Prevenção de fraudes e segurança | Sim |

- Dados criptografados em trânsito: **sim**.
- Pessoa pode pedir exclusão: **sim**, no app (Perfil > Meus dados > Excluir
  minha conta) e pelo endereço `#excluir-conta`.
- Preferências, conteúdos salvos, progresso de leitura e conversas ficam
  **só no aparelho**. Pelas regras da Play, isso não conta como coleta.
- Localização: **não coletada**. "Ver unidades perto de mim" só abre o app de
  mapas do celular com um termo de busca.
- Localização: **não coletada**. "Ver unidades perto de mim" só abre o app
  de mapas do celular com um termo de busca.

O item mais sensível é a pergunta enviada ao Gemini: no plano gratuito, o Google
pode usar o texto para melhorar os próprios serviços. Por isso ele aparece como
"compartilhado". Para não precisar declarar isso, mude o AI Logic para a
**Vertex AI Gemini API**, que exige o plano Blaze e não usa os dados para treino.
