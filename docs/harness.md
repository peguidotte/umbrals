# Harness modular e ciclo de desenvolvimento

A entrada comum é `python tools/harness.py`. O registro em
`tools/harness_lib/registry.py` é a fonte das tarefas, dependências, filtros,
relatórios e cobertura exigida no fechamento. `check.sh`, `build.sh`, `ui_checks.py`,
`iterate.py` e CI utilizam esse registro; não mantenha outra lista de suítes nesses wrappers.

## Descobrir e rodar um alvo

```bash
python tools/harness.py list --json
python tools/harness.py check --suite architecture
python tools/harness.py check --suite effects --case enemy_shield
python tools/harness.py check --suite rules --case traits
python tools/harness.py check --suite harness-core --case snapshot
python tools/harness.py check --suite inventory,lifecycle --jobs 2
python tools/harness.py browser --scenario inventory --viewport 1280x720 --large-text
python tools/harness.py browser --scenario inventory --fixture inventory_full --viewport 1280x720 --large-text
python tools/harness.py browser --scenario combat --fixture enemy_shield --video
python tools/harness.py browser --scenario rewards --fixture branching_rewards
python tools/harness.py browser --scenario replacement
python tools/harness.py browser --scenario persistence
python tools/harness.py browser --scenario layout --viewport 1024x768
```

`--suite` aceita uma ou mais tarefas, separadas por vírgula. Dependências são resolvidas
automaticamente. `--case` exige uma única suíte compatível; filtros desconhecidos ou
ignorados não produzem um passe vazio. O relatório GDScript deve confirmar o caso
executado e sua lista exclusiva. Use `list` para os nomes suportados.

Cenários independentes: `navigation`, `inventory`, `combat`, `rewards`, `replacement`,
`persistence`, `layout` e `integration`. A matriz normal/ampliada tem sua própria tarefa.
`integration` percorre o caminho real desde o menu, vitória, recarga, substituição e itens;
ela conserva as asserções anteriores. A persistência focada verifica preferências; a
persistência de estatísticas de vitória também exige a integração completa.

As fixtures são condições iniciais de teste: batalha, time ferido, escudo inimigo,
recompensas, quatro ofertas com ramificação, time completo para substituição e dez itens.
Comandos exercitados são cliques/teclas reais. O inventário cheio verifica Tab por todos
os controles, inclusive os que começam fora do recorte. O diagnóstico de geometria espera
o layout após foco/rolagem; não use sleeps arbitrários para esconder coordenadas antigas.

## Fixtures e replays

`tests/support/scenario_fixtures.gd` constrói as condições iniciais com catálogo próprio.
`tools/make_fixtures.gd` valida os snapshots e confirma que o replay reproduz cada resultado.
A tarefa `fixtures` produz `fixtures.json` e arquivos individuais em `fixture-records/`.

```bash
python tools/harness.py check --suite fixtures
python tools/harness.py replay --input <execução>/tasks/fixtures/fixture-records/replacement.json
```

O snapshot completo é `game.export_state()`, versão 1, e é restaurado com
`game.restore_state(data)`. `game.snapshot()` permanece um diagnóstico, não um save.
O checkpoint inclui saúde, fase, orçamentos, indivíduos, pilhas, seleção, ofertas, estados,
inventário, equipamento, histórico, último resultado, próximo UID e estado exato do RNG.
Inteiros de seed/RNG são strings decimais para evitar perda de precisão no JSON.

A restauração valida referências, índices, conservação das cartas, equipamento, ofertas,
limites e identidade semântica do catálogo antes de escrever qualquer estado. Um erro
preserva a partida existente. Requests derivados de prévia são recalculados, não são um
formato de persistência. O replay aceita somente comandos conhecidos e para no primeiro
comando inválido, informando seu índice e o estado após o prefixo válido.

A entrada `tests/browser/fixture_entry.tscn` existe apenas no projeto Web temporário de
fixtures. A exportação de produção continua excluindo `tests/`. A checagem do PCK verifica
essa fronteira explicitamente, executando a leitura em diretório vazio para impedir fallback
a arquivos do checkout. Não adicione setters ou comandos à ponte JavaScript do jogo.
As preferências iniciais de fonte ampliada são configuração do boot de teste; o caminho
normal de acessibilidade continua exercitado por controles reais na integração/matriz.

## Planejamento incremental

```bash
python tools/harness.py plan --suite effects
python tools/harness.py plan --changed
python tools/harness.py plan --changed --since <execução-anterior>
```

O plano lista os arquivos que atingem cada tarefa e as dependências incluídas. A seleção
é conservadora por grupos de entradas declaradas, não uma análise semântica perfeita.
O padrão compara com a última aceitação completa; antes dela utiliza alterações e arquivos
novos do Git. `--since` permite comparar com o manifesto de outra execução.

Um catálogo por instância elimina fixtures que editam `Content.SPECIES` globalmente.
Passe um catálogo explícito ao construir `Rules`, ou edite o fork da própria partida.
O planejador separado enumera apenas subconjuntos de até três cartas e mantém o desempate
antigo. Doze cartas geram 298 candidatos; vinte e quatro geram 2.324.

## Isolamento, cache e retomada

Cada execução tem diretório único em `artifacts/harness/`, manifesto de fontes,
`harness-run.json`, resumo `run.json`, diretórios `tasks/<nome>/` e logs. Dados de usuário
nos testes nativos são privados daquela tarefa. Não apague nem sobrescreva relatórios
anteriores para executar uma suíte.

```bash
python tools/harness.py resume --from <execução-ou-harness-run.json>
python tools/harness.py check --suite effects --fresh
```

Importação e builds podem ser reutilizados se seus fingerprints e todos os arquivos de
saída ainda corresponderem. Fingerprints incluem entradas, políticas do projeto, código do
runner, ferramentas/opções e resultados relevantes das dependências. Cache corrompido é
reconstruído. A importação tem marcador do projeto e lock próprio. O build retornado é
fixado ao diretório da execução; `builds/web` é somente o atalho compatível para uso humano.

A retomada reaproveita tarefas anteriores aprovadas apenas quando fingerprint e saídas
conferem, registrando a origem. Entradas alteradas fazem a tarefa rodar novamente. `--fresh`
impede reaproveitamento. Testes comportamentais da aceitação completa sempre rodam de novo;
a otimização normal do fechamento é reaproveitar importação/exportação válidas.

Tarefas nativas independentes podem rodar em paralelo. Importação/exportação do projeto e
navegadores têm locks; iniciar vários Chromium/software WebGL indiscriminadamente costuma
competir pela mesma CPU. Não retire os locks para aumentar o número nominal de workers.

Resultados distinguem `passed`, `failed`, `cached`, `skipped` e `interrupted`. SIGINT/SIGTERM
interrompem o grupo de processos e deixam relatório durável. Nenhum passo omitido vira
aprovação. `--json` fornece o relatório sem mensagens de progresso para consumo por IA.

Uma tarefa focada verifica suas próprias entradas. Uma edição paralela em documentação
não relacionada pode deixar o hash global inicial diferente do final, mantendo evidência
válida somente do alvo; o relatório registra ambos. Na aceitação completa, todas as fontes
ficam congeladas até o final. Mudança durante o fechamento invalida a entrega.

## Fechamento e revisão

```bash
python tools/harness.py verify --full --video
python tools/iterate.py --label minha-entrega --goal 'Resultado observável' --baseline <evidência-anterior> --video
```

`verify` produz a evidência completa em JSON e as capturas por cenário. `iterate` usa o
mesmo grafo e acrescenta comparação com baseline e HTML/ZIP de revisão. Para refazer somente
a apresentação de uma evidência existente, use `iterate.py --review-only <execução>`.

Uma aceitação completa exige todas as tarefas do registro, os oito cenários, matriz de
cinco formatos, validação do PCK, fixtures, mutações, testes do harness e galeria. Filtros de
caso, fixture ou viewport não são aceitos em `verify --full`. O CI rejeita um resultado focado,
ainda que esteja verde. Use a suíte afetada durante implementação; execute o fechamento
completo depois de resolver os problemas e congelar as fontes.

`harness_runner_test.py` verifica cache, corrupção, filtros, dependências, paralelismo,
retomada, isolamento, interrupção e distinção entre evidência focada e aceitação completa.
Também verifica símbolos globais dos módulos de navegador sem depender de Playwright,
para detectar imports perdidos ao extrair cenários. A integração vem antes da matriz no
fechamento, antecipando regressões no caminho de produção.
Não enfraqueça esses contratos para obter um tempo menor.

`action-timings.json` mede carregamentos, cliques, teclas e capturas. Os relatórios registram
tempos por tarefa e o uso de cache. Compare o mesmo alvo, viewport e opções em medições de
lead time; um teste focado verde não substitui cobertura completa, revisão visual ou playtest.
