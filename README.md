<p align="center">
  <img src="assets/icone/icone.png" alt="Ícone do CuidaIA" width="120">
</p>

<h1 align="center">CuidaIA</h1>

<p align="center">
  Educação em saúde e orientação sobre o SUS, em linguagem simples.<br>
  Trabalho de Conclusão de Curso · Unitins
</p>

<p align="center">
  <a href="https://cuidaia-41f74.web.app"><b>Abrir a versão web</b></a> ·
  <a href="docs/DOCUMENTACAO.md">Documentação completa</a> ·
  <a href="docs/arquitetura.md">Arquitetura e limitações</a>
</p>

---

O CuidaIA explica como o SUS se organiza e ajuda a pessoa a descobrir **onde
procurar atendimento**: UBS, UPA, hospital, CAPS ou SAMU 192. Para isso, ele
junta conteúdos revisados, um assistente com inteligência artificial e uma
triagem local de risco.

> **O CuidaIA orienta, mas não faz diagnóstico.** Ele não indica remédios nem
> substitui o atendimento profissional. Em emergência, ligue **192**.

## Funcionalidades

- **Assistente com IA (Gemini).**
  - Responde dúvidas sobre o SUS em linguagem simples.
  - Cita sempre uma fonte oficial. As fontes vêm de uma lista fechada, então
    nenhum link é inventado.
  - Quando a pessoa descreve o que sente, sugere o **nível de atenção**
    adequado e explica o porquê.
- **Triagem de risco local.** Frases como "dor no peito" ou "não quero mais
  viver" mostram na hora o SAMU 192 ou o CVV 188. Funciona sem internet e sem
  depender da IA.
- **"Ver unidades perto de mim".** Abre o app de mapas do celular com a busca
  pelo tipo de unidade (UBS, UPA, CAPS). O CuidaIA não acessa a localização.
- **"Onde devo ser atendido?".** Quatro perguntas rápidas que indicam o serviço.
- **Aprenda.**
  - Artigos sobre a Rede de Atenção à Saúde e os níveis primário, secundário e
    terciário;
  - diagrama da rede, exemplo de percurso e busca;
  - progresso de leitura ("Continue lendo").
- **Acessibilidade.**
  - texto maior;
  - alto contraste;
  - fonte de leitura facilitada (Atkinson Hyperlegible);
  - menos movimento;
  - leitura em voz alta.
- **Notificações** (Android). Dica da semana e lembrete de leitura, ambas
  locais e opcionais.
- **Conta.**
  - E-mail e senha ou Google;
  - recuperação de senha e edição do perfil com foto;
  - exclusão da conta.
- **LGPD.** O app permite consultar, baixar (JSON) e excluir os dados, e
  explica a política de privacidade em linguagem simples.

## Tecnologias

| Camada | Tecnologia | Por quê |
|---|---|---|
| Interface | **Flutter 3.47 / Dart 3.13** | Um código para Android e web, com o mesmo visual em todos os aparelhos. |
| Login | **Firebase Authentication** | E-mail/senha e Google sem servidor próprio, com e-mails em português. |
| Perfil | **Cloud Firestore** | Banco gerenciado; as regras garantem que cada pessoa só acessa o próprio perfil. |
| IA | **Firebase AI Logic + Gemini 3.5 Flash** | Nenhuma chave de API no app; resposta em JSON com esquema fixo. |
| Proteção | **Firebase App Check** | Só o app verdadeiro usa a cota da IA. |
| Web | **Firebase Hosting** | Versão web e política de privacidade pública, com HTTPS. |
| Aparelho | `shared_preferences`, `flutter_local_notifications`, `flutter_tts`, `url_launcher`, `image_picker`, `share_plus` | Preferências locais, notificações sem servidor, voz, discador e mapas, foto e exportação de dados. |

Todo o backend roda no **plano gratuito (Spark)** do Firebase. O motivo de cada
escolha está explicado em [docs/DOCUMENTACAO.md](docs/DOCUMENTACAO.md#3-tecnologias-e-justificativas).

## Arquitetura em resumo

```
Telas (screens/, widgets/, theme/)
        │
Estado (state/: AppState e ChatController)
        │
Serviços e dados (services/, data/)
        │
Firebase (Auth, Firestore, AI Logic/Gemini, App Check)  ·  Aparelho (preferências, notificações, voz, mapas)
```

- Cada serviço externo é uma **interface com duas implementações**: uma real
  (Firebase/Gemini) e uma em memória, usada nos testes.
- Uma pergunta ao assistente segue esta ordem:
  1. passa pela **triagem local**;
  2. pergunta frequente recebe uma **resposta pronta**, sem gastar cota;
  3. as demais vão ao **Gemini**, que devolve parágrafos, a chave da fonte, o
     nível sugerido e a justificativa.

## Estrutura

```
lib/
  main.dart                    Entrada: Firebase, App Check, notificações
  app.dart                     MaterialApp, tema e acessibilidade
  data/                        Triagem, instrução da IA, serviços e conteúdos
  services/                    Conta (Firebase), notificações, voz, links e mapas
  state/                       AppState (sessão, preferências) e ChatController
  screens/                     Login, cadastro, Início, Assistente, Aprenda, Artigo, Perfil
  theme/                       Identidade visual 2.0 (Manrope, verde #137567, petróleo)
  widgets/                     Botões, campos, cartões, avisos, logo
test/                          31 testes automatizados
tool/                          Avaliação da IA por cenários e gerador do ícone
avaliacao/                     Cenários de avaliação
docs/                          Documentação completa, arquitetura e publicação
web/                           Página web e política de privacidade pública
firestore.rules                Regras de segurança do banco
```

O papel de cada arquivo, classe e função está em
[docs/DOCUMENTACAO.md](docs/DOCUMENTACAO.md#6-documentação-do-código-arquivo-por-arquivo).

## Como rodar

### Pré-requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47 ou mais recente;
- [Firebase CLI](https://firebase.google.com/docs/cli) e FlutterFire CLI
  (`dart pub global activate flutterfire_cli`);
- JDK 17 ou mais recente, para o Android.

### Passos

```bash
flutter pub get
flutter analyze
flutter test        # não precisa de Firebase nem de internet
flutter run --dart-define-from-file=app_check.local.json
```

O arquivo `app_check.local.json` guarda o token de depuração do App Check. Ele
fica fora do git; os passos para gerar o token estão na seção de configuração
do Firebase, abaixo. O botão **Executar** do VS Code já passa esse arquivo
(`.vscode/launch.json`).

### Configurar o Firebase (projeto novo)

1. Entre na conta Google e crie o projeto:

   ```bash
   firebase login
   firebase projects:create cuidaia-<sufixo> --display-name CuidaIA
   flutterfire configure --project=cuidaia-<sufixo> --platforms=android,web
   ```

2. No [Console do Firebase](https://console.firebase.google.com), faça as
   seguintes configurações:

   | Serviço | O que fazer |
   |---|---|
   | **Authentication** | Ative **E-mail/senha** e **Google**. |
   | **Configurações do projeto > Android** | Cadastre o SHA-1 e o SHA-256 da chave de debug e da de release. O login com Google no Android depende disso. |
   | **Firestore** | Crie o banco em modo de produção, no local `southamerica-east1`. |
   | **AI Logic** | Escolha a **Gemini Developer API** (sem custo). |

   Para ver o SHA-1 e o SHA-256 da chave de debug, rode:

   ```bash
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android
   ```

3. Publique as regras do banco:

   ```bash
   firebase deploy --only firestore:rules
   ```

4. Configure o **App Check**:
   - **Desenvolvimento:**
     1. Gere um token em *App Check > Apps > ⋮ > Gerenciar tokens de
        depuração*.
     2. Crie o arquivo `app_check.local.json` com o conteúdo
        `{"APP_CHECK_DEBUG_TOKEN": "<token>"}`.
   - **Web publicada:** registre uma chave do reCAPTCHA Enterprise (Fraud
     Defense), do tipo pontuação, com os domínios do Hosting. A chave do
     projeto está em `lib/main.dart`.
   - **Android da loja:** registre o Play Integrity.

Para trocar o modelo da IA sem mexer no código, use
`--dart-define=GEMINI_MODELO=<nome>`.

## Compilar e publicar

| Saída | Comando |
|---|---|
| Android para a loja (.aab) | `flutter build appbundle --release` |
| APK para instalar direto | `flutter build apk --release --split-per-abi` |
| APK de avaliação (banca) | `flutter build apk --release --split-per-abi --dart-define-from-file=app_check.avaliacao.local.json` |
| Web | `flutter build web --release` e depois `firebase deploy --only hosting` |

**Arquivos que ficam fora do git:**
- `android/key.properties` e `android/app/upload-keystore.jks`, a chave de
  release e a senha dela;
- `*.local.json`, os tokens de depuração.

**APK de avaliação.** O Play Integrity só aprova apps baixados da loja. Por
isso, o APK de avaliação usa um token próprio, que pode ser revogado no console
depois da avaliação.

**Ícone.** Para refazer as imagens do ícone, rode:

```bash
flutter test tool/gerar_icones_test.dart
dart run flutter_launcher_icons
```

O roteiro da Play Store, com a ficha da loja, os questionários e o formulário
de segurança dos dados, está em [docs/publicacao.md](docs/publicacao.md).

## Avaliação da IA

Esta é a parte do TCC que mede se o nível de atenção sugerido pelo app está
certo. O roteiro [`tool/avaliar_cenarios.dart`](tool/avaliar_cenarios.dart)
passa cada cenário de [`avaliacao/cenarios.csv`](avaliacao/cenarios.csv) pela
mesma triagem e pela mesma configuração do Gemini que o app usa, e calcula:
- acurácia;
- matriz de confusão;
- precisão e revocação por nível;
- subtriagem.

Os detalhes estão em [avaliacao/README.md](avaliacao/README.md).

## Privacidade

- O app pede só nome, e-mail e senha; apelido e foto de perfil são opcionais. Ele não pede dados de saúde.
- As preferências e as conversas ficam só no aparelho.
- O texto das perguntas livres vai ao Gemini sem nome e sem e-mail.
- A localização não é coletada.

Política completa: [web/privacidade.html](web/privacidade.html)
(publicada em https://cuidaia-41f74.web.app/privacidade.html).

## Documentação

| Documento | Conteúdo |
|---|---|
| [docs/DOCUMENTACAO.md](docs/DOCUMENTACAO.md) | Documentação técnica completa: funcionalidades, tecnologias e justificativas, arquitetura, cada arquivo e função, fluxos, IA, LGPD, segurança, acessibilidade, testes. |
| [docs/arquitetura.md](docs/arquitetura.md) | Arquitetura, caminho de uma pergunta e limitações (para o TCC). |
| [docs/publicacao.md](docs/publicacao.md) | Roteiro de publicação na Google Play. |
| [avaliacao/README.md](avaliacao/README.md) | Avaliação da classificação orientativa. |

## Autor

**Zairo Lins Ribeiro Cunha**: zairolins15@gmail.com
Trabalho de Conclusão de Curso, Unitins, 2026.
