# Avaliação da classificação orientativa

Material para o objetivo específico 4 do TCC: verificar se o nível de atenção que o CuidaIA sugere é coerente com a organização do SUS.

## Arquivos

- `cenarios.csv` traz os cenários simulados, com as colunas `id`, `texto` e `esperado`.
  - Os 18 cenários atuais são **exemplos** para testar o roteiro. O conjunto final, com 40 a 60 cenários, precisa ter o gabarito revisado por um profissional de saúde.
  - Valores aceitos em `esperado`: `primaria`, `secundaria`, `terciaria`, `urgencia`, `psicossocial`, `nao_se_aplica`.
- `resultados_<data>.csv` é gerado a cada execução, com uma linha por cenário e repetição.

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

Por padrão ele espera 4 s entre as chamadas, para respeitar a cota gratuita. Esse tempo pode ser ajustado com `--pausa-ms`.

## Métricas impressas

- acurácia;
- matriz de confusão;
- precisão e revocação por nível;
- **subtriagem**: casos de urgência classificados como outro nível (o erro mais grave);
- sobretriagem: outros níveis classificados como urgência.

Para medir a consistência, compare as repetições de um mesmo `id` no CSV de resultados.

## Reprodutibilidade

Antes da rodada oficial, crie uma tag da versão avaliada (por exemplo, `git tag avaliacao-v1`) e anote no TCC o modelo, a temperatura e a data da execução.
