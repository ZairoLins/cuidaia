# CuidaIA

Aplicativo de educação em saúde e orientação sobre o SUS, em linguagem simples.
Implementação em Flutter do protótipo "CuidaIA — Protótipo mobile".

## Como rodar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Antes do primeiro `flutter run`, configure o Firebase (abaixo). Os testes não precisam dele.

## Estrutura

```
lib/
  main.dart, app.dart          Entrada, Firebase, App Check, tema e acessibilidade
  firebase_options.dart        Gerado pelo `flutterfire configure`
  theme/cuida_tema.dart        Identidade visual 2.0: Manrope, verde de ação #137567, petróleo, estados, cantos e alto contraste
  state/app_state.dart         Sessão, acessibilidade, notificações, salvos e progresso de leitura
  state/chat_controller.dart   Estados do chat: vazio, enviada, processando, resposta, orientação, emergência, erro
  data/assistente.dart         Triagem de risco, serviços (SAMU, UPA, UBS, CAPS) e respostas prontas
  data/assistente_gemini.dart  Assistente com Gemini (Firebase AI Logic)
  data/conteudos.dart          Artigos sobre a Rede de Atenção à Saúde e referências oficiais
  services/conta.dart          Interface de conta + versão em memória (testes)
  services/conta_firebase.dart Firebase Auth (e-mail/senha e Google) + perfil no Firestore
  services/lembretes.dart      Notificações locais: dica da semana e lembrete de leitura
  services/                    Links e ligações (url_launcher) e leitura em voz alta (flutter_tts)
  widgets/                     Logo, botões, campos, cartões, interruptores
  screens/                     Login, cadastro, abas (Início, Assistente, Aprenda, Perfil), artigo e telas do perfil
firestore.rules                Cada pessoa só lê e escreve o próprio perfil
hosting/                       Política de privacidade e exclusão de conta (páginas públicas)
docs/                          Roteiro de publicação; arquitetura e limitações (TCC)
assets/icone/                  Ícone do app gerado a partir do símbolo
tool/                          Avaliação por cenários e gerador do ícone
```

## Backend no Firebase (plano Spark, gratuito)

| Recurso | Serviço | Observação |
|---|---|---|
| Login, cadastro, nova senha, troca de e-mail | Firebase Authentication | E-mails enviados pelo próprio Firebase, em português |
| Login com Google | Firebase Authentication | Popup na web, aba do navegador no Android; sem pacote extra |
| Perfil (nome, apelido, e-mail, foto) | Cloud Firestore, `usuarios/{uid}` | Foto reduzida para 256 px e guardada no documento |
| Assistente | Firebase AI Logic + Gemini Developer API | Nenhuma chave de API no app |
| Proteção da cota da IA | App Check | Play Integrity / App Attest / Fraud Defense (web) |

O Cloud Storage não é usado porque, desde fevereiro de 2026, ele exige o plano Blaze.
As conversas não são salvas no servidor: ficam só no aparelho até a pessoa sair.

### Configurar o Firebase

1. Entre na conta Google: `firebase login`
2. Crie o projeto (ou use um existente) e gere `lib/firebase_options.dart`:
   ```bash
   firebase projects:create cuidaia-<sufixo> --display-name CuidaIA
   flutterfire configure --project=cuidaia-<sufixo> --platforms=android,web
   ```
3. No [Console do Firebase](https://console.firebase.google.com):
   - **Authentication > Método de login**: ative **E-mail/senha** e **Google**.
   - No Android, o login com Google exige o SHA-1 e o SHA-256 do certificado em
     **Configurações do projeto > Seus apps > Android**. Para a chave de debug:
     `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`.
     Ao criar a chave de release, cadastre também os SHA dela.
   - **Authentication > Modelos**: mude o idioma para português, se quiser.
   - **Firestore Database > Criar banco**: modo de produção, local `southamerica-east1` (São Paulo).
   - **AI Logic > Começar**: escolha **Gemini Developer API** (sem custo).
4. Publique as regras do banco: `firebase deploy --only firestore:rules`
5. App Check (a configuração do AI Logic já deixa a proteção ativa, então sem
   isso o assistente responde com erro 401):
   - Em desenvolvimento (`flutter run`), web e Android usam um **token de depuração**.
     Gere um em **App Check > Apps > (app) > ⋮ > Gerenciar tokens de depuração >
     Gerar token**, cole em `app_check.local.json` (ignorado pelo git) e rode com
     `flutter run --dart-define-from-file=app_check.local.json`, ou pelo botão
     Executar do VS Code (`.vscode/launch.json` já passa o arquivo).
   - Web publicada: o reCAPTCHA v3 clássico não é mais aceito. Crie uma chave de site do
     **Fraud Defense** (antigo reCAPTCHA Enterprise), do tipo "Site", com
     verificação por pontuação, no mesmo projeto do Google Cloud. Registre-a no
     App Check. A chave do projeto já está em `lib/main.dart`; para usar
     outra, rode com `--dart-define=RECAPTCHA_SITE_KEY=<chave>`.
   - Para publicar: registre o Play Integrity (Android) e App Attest (iOS).

O modelo pode ser trocado sem mexer no código: `--dart-define=GEMINI_MODELO=<nome>`.

## Integração com a IA

A triagem por palavras-chave (`classificar`) roda antes da IA: situações de risco
sempre mostram SAMU 192 ou CVV 188, sem depender da rede. As perguntas sugeridas
usam respostas prontas e revisadas, e não gastam cota. As demais vão para o Gemini,
que responde em JSON estruturado e escolhe a fonte numa lista fixa de documentos
oficiais (`fontesOficiais`), então nenhum link é inventado.

## Release (Android)

A chave de upload fica em `android/app/upload-keystore.jks` e a senha em
`android/key.properties`. Os dois arquivos ficam **fora do git**; guarde uma
cópia em lugar seguro. Sem eles, o release é assinado com a chave de debug.

```bash
flutter build appbundle --release            # para a Play Store (.aab)
flutter build apk --release --split-per-abi  # APK para instalar direto (use o arm64-v8a)
```

Ícone: `flutter test tool/gerar_icones_test.dart` gera as imagens a partir do
símbolo, e `dart run flutter_launcher_icons` gera os tamanhos de cada plataforma.

Roteiro completo da loja, com Firebase, ficha, questionários e segurança dos
dados: [docs/publicacao.md](docs/publicacao.md). Arquitetura e limitações para
o TCC: [docs/arquitetura.md](docs/arquitetura.md).

## Pendências

- Atualizar a data de revisão em `aprenda_screen.dart` quando os conteúdos forem revisados.
- Cadastrar no Firebase os SHA da chave de release (ver `docs/publicacao.md`).
- Publicar as páginas de privacidade: `firebase deploy --only hosting`.
