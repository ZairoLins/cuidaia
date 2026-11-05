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
  theme/cuida_tema.dart        Cores, tipografia (Newsreader, Geist, Atkinson Hyperlegible) e alto contraste
  state/app_state.dart         Sessão, acessibilidade, notificações e conteúdos salvos (shared_preferences)
  state/chat_controller.dart   Estados do chat: vazio, enviada, processando, resposta, orientação, emergência, erro
  data/assistente.dart         Triagem de risco, serviços (SAMU, UPA, UBS, CAPS) e respostas prontas
  data/assistente_gemini.dart  Assistente com Gemini (Firebase AI Logic)
  data/conteudos.dart          Artigos sobre a Rede de Atenção à Saúde e referências oficiais
  services/conta.dart          Interface de conta + versão em memória (testes)
  services/conta_firebase.dart Firebase Auth (e-mail e senha) + perfil no Firestore
  services/                    Links e ligações (url_launcher) e leitura em voz alta (flutter_tts)
  widgets/                     Logo, botões, campos, cartões, interruptores
  screens/                     Login, cadastro, abas (Início, Chat, Aprenda, Perfil), artigo e telas do perfil
firestore.rules                Cada pessoa só lê e escreve o próprio perfil
```

## Backend no Firebase (plano Spark, gratuito)

| Recurso | Serviço | Observação |
|---|---|---|
| Login, cadastro, nova senha, troca de e-mail | Firebase Authentication | E-mails enviados pelo próprio Firebase, em português |
| Perfil (nome, apelido, e-mail, foto) | Cloud Firestore, `usuarios/{uid}` | Foto reduzida para 256 px e guardada no documento |
| Assistente | Firebase AI Logic + Gemini Developer API | Nenhuma chave de API no app |
| Proteção da cota da IA | App Check | Play Integrity / App Attest / reCAPTCHA v3 |

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
   - **Authentication > Método de login**: ative **E-mail/senha**.
   - **Authentication > Modelos**: mude o idioma para português, se quiser.
   - **Firestore Database > Criar banco**: modo de produção, local `southamerica-east1` (São Paulo).
   - **AI Logic > Começar**: escolha **Gemini Developer API** (sem custo).
4. Publique as regras do banco: `firebase deploy --only firestore:rules`
5. App Check:
   - Android, em modo debug: rode o app, copie o *debug token* que aparece no console e
     cadastre-o em **App Check > Apps > Gerenciar tokens de depuração**.
   - Web: crie uma chave reCAPTCHA v3, registre-a no App Check e rode com
     `flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<chave>`.
   - Para publicar: registre o Play Integrity (Android) e App Attest (iOS).

O modelo pode ser trocado sem mexer no código: `--dart-define=GEMINI_MODELO=<nome>`.

## Integração com a IA

A triagem por palavras-chave (`classificar`) roda antes da IA: situações de risco
sempre mostram SAMU 192 ou CVV 188, sem depender da rede. As perguntas sugeridas
usam respostas prontas e revisadas, e não gastam cota. As demais vão para o Gemini,
que responde em JSON estruturado e escolhe a fonte numa lista fixa de documentos
oficiais (`fontesOficiais`), então nenhum link é inventado.

## Pendências

- Preencher `[NOME DO ENCARREGADO]`, `[E-MAIL DO ENCARREGADO]` (Privacidade),
  `[E-MAIL DE CONTATO]` (Termos) e `[DATA DA REVISÃO]` (Aprenda).
- Trocar o `applicationId` `com.example.cuidaia` antes de publicar na Play Store.
