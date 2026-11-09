# Avaliação da classificação orientativa

Material para o objetivo específico 4 do TCC: verificar se o nível de atenção que o CuidaIA sugere é coerente com a organização do SUS.

## Arquivos

- `cenarios.csv` traz os cenários simulados, com as colunas `id`, `texto` e `esperado`.
  - São 60 cenários, 10 por nível. O gabarito precisa ser revisado por um profissional de saúde (ou pelo orientador) antes da rodada oficial.
  - Três cenários (U04, U06 e M07) contêm palavras-chave de risco e são resolvidos pela primeira camada, sem chamar o modelo.
  - Valores aceitos em `esperado`: `primaria`, `secundaria`, `terciaria`, `urgencia`, `psicossocial`, `nao_se_aplica`.
- `resultados.csv` é gravado a cada execução, com uma linha por cenário e repetição (outro nome pode ser escolhido com `--saida`).

## Como rodar

1. Gere uma chave da Gemini API no Google AI Studio. Ela fica só na variável de ambiente e **nunca** vai para o repositório.
2. Na raiz do projeto (PowerShell):

```powershell
$env:GEMINI_API_KEY = "<sua chave>"
dart run tool/avaliar_cenarios.dart --cenarios avaliacao/cenarios.csv --repeticoes 3
```

O roteiro passa cada cenário pelas mesmas duas camadas do app:

1. a triagem por palavras-chave (`lib/data/triagem.dart`);
2. o Gemini, com a mesma instrução, o mesmo formato de resposta, o mesmo modelo e a mesma temperatura (`lib/data/instrucoes_assistente.dart`).

Por padrão ele espera 7 s entre as chamadas, para respeitar o limite por minuto da cota gratuita. Esse tempo pode ser ajustado com `--pausa-ms`.

### Cota e retomada

- Erros temporários (HTTP 429 por limite por minuto, 500 e 503) são repetidos até 5 vezes, com a espera que a própria API indicar.
- Se a **cota diária** acabar, o roteiro para e salva o que já fez. Rode o mesmo comando depois que a cota renovar: ele reaproveita as execuções já gravadas em `resultados.csv` e só chama a API para as que faltam ou falharam.
- Falhas de API aparecem como `obtido=erro` e ficam **fora** das métricas.
- Depois de revisar o gabarito, rode o comando de novo: as métricas são recalculadas com o `esperado` atual, sem chamar o modelo.
- Para começar do zero, apague `resultados.csv`.

## Métricas impressas

- acurácia;
- matriz de confusão;
- precisão e revocação por nível;
- **subtriagem**: casos de urgência classificados como outro nível (o erro mais grave);
- sobretriagem: outros níveis classificados como urgência.

Para medir a consistência, compare as repetições de um mesmo `id` no CSV de resultados.

## Reprodutibilidade

Antes da rodada oficial, crie uma tag da versão avaliada (por exemplo, `git tag avaliacao-v1`) e anote no TCC o modelo, a temperatura e a data da execução.
