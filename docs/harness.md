# Harness da main atual

O registro `tools/harness_lib/registry.py` define tarefas, dependências, filtros,
grupos nativos e cobertura. CLI, wrappers e CI usam esse registro.

## Antes de desenvolver

```bash
python tools/harness.py preflight --fetch
```

`main` significa a main atual do GitHub. O preflight informa SHA local/remoto,
divergência e arquivos modificados; retorna 2 quando a branch ficou para trás.
Não altera o checkout. Faça o fetch antes de planejar, não durante o fechamento.
Uma aceitação antiga só comprova a revisão que seu manifesto identifica.

## Rodar um alvo

```bash
python tools/harness.py list --json
python tools/harness.py plan --changed
python tools/harness.py check --suite rules --case natures_and_reactions
python tools/harness.py check --suite rules --case swaps_and_ko
python tools/harness.py check --suite harness-core --case checkpoint
python tools/harness.py check --suite expedition-save,settings --jobs 2
python tools/harness.py browser --scenario inventory --viewport 1280x720 --large-text
python tools/harness.py browser --scenario combat --fixture enemy_shield
python tools/harness.py browser --scenario replacement
python tools/harness.py browser --scenario layout --viewport 1024x768
python tools/harness.py browser --scenario expedition
python tools/harness.py browser --scenario title
```

`--suite` aceita CSV/repetição. Dependências são automáticas. `--case` exige uma
única suíte compatível e confirmação do caso executado no relatório GDScript.
Filtros desconhecidos e suítes vazias falham. `--json` omite o progresso e retorna
um relatório para consumo pela IA. `list` expõe os casos e a lista de fechamento.

Os dez cenários são integration, layout, navigation, inventory, combat, rewards,
replacement, persistence, expedition e title. Integração conserva as asserções da
main: quatro rotas de treino, reações, nocaute, reservas, captura/evolução,
planejamento e informações inimigas. Expedição cobre mapa, bifurcação e save/continuar.
Menu valida as cinco opções Web (seis no desktop nativo) e a apresentação atual. Layout cobre os cinco formatos.

Os fluxos atuais são autoritativos: uma a três posições ativas, até seis integrantes,
HP individual, três ações compartilhadas e itens confirmados ao Conjurar. Não restaure
as expectativas antigas de três integrantes totais, HP coletivo, itens gratuitos ou
evolução adicionando automaticamente cartas.

`title_checks.py`, `expedition_checks.py` e `ui_checks.py` são wrappers focados;
`check.sh` roda o conjunto headless completo. Nenhum resultado focado é uma entrega
completa, mesmo quando está verde.

## Fixtures, checkpoints e replay

`tests/support/scenario_fixtures.gd` constrói sete condições iniciais sobre o combate
atual: batalha, ferido, escudo inimigo, recompensa, várias ofertas, seis integrantes
para substituição e mochila do time completo. Fixtures alteram somente sua instância;
não editam o catálogo global. Ofertas são produzidas por uma conjuração real.

A tarefa `fixtures` restaura o estado inicial, reproduz os comandos e compara o
checkpoint final para cada caso. Produz `fixtures.json` e `fixture-records/<nome>.json`.

```bash
python tools/harness.py check --suite fixtures
python tools/harness.py replay --input <execução>/tasks/fixtures/fixture-records/replacement.json
```

O formato é o checkpoint da expedição existente: `Expedition.snapshot()` e
`Expedition.restore()`. Preserve RNG em strings exatas, intenção já comprometida,
cópias canônicas, zonas, incapacitação, reservas, ofertas e estado do mapa. Restore
valida um candidato separado e descarta planos ainda não confirmados, conforme o
contrato atual de continuar partida. Não introduza outro save concorrente com ele.

`expedition/replay.gd` aceita somente comandos explícitos das APIs de produção.
Comando inválido informa o índice e mantém o estado após o prefixo válido. Não há setter
arbitrário. Fixtures entram por `tests/browser/fixture_entry.tscn` em um projeto Web
temporário; a ponte JavaScript pública continua somente leitura.

O PCK de produção deve excluir script, cena e dados das fixtures. A leitura ocorre em
diretório vazio, evitando fallback para arquivos do checkout. Scripts compilados são
verificados com ResourceLoader; FileAccess sozinho não reconhece seu remapeamento.

## Cache, isolamento e retomada

```bash
python tools/harness.py plan --changed --since <execução-anterior>
python tools/harness.py resume --from <execução-ou-harness-run.json>
python tools/harness.py check --suite rules --case visibility --fresh
```

Cada run tem diretório único em `artifacts/harness/`, manifesto, relatório bruto,
resumo e `tasks/<nome>/`. Testes nativos têm user data privado. Importação e exports
podem usar cache somente se entradas/políticas/ferramentas/opções e hashes das saídas
conferirem. Corrupção invalida o cache. `--fresh` impede reaproveitamento, inclusive
na retomada. A origem dos resultados reutilizados permanece registrada.

O plano compara entradas declaradas com uma aceitação anterior ou Git. É conservador,
não uma análise semântica perfeita. Alterações de dependências também atingem seus
consumidores; importação é uma dependência de ordenação dos testes de regras.

Workers nativos são limitados; import/export e browser têm locks. Tarefas com o mesmo
lock não preenchem workers aguardando outra tarefa do próprio run. Locks de arquivo
coordenam execuções simultâneas. Métricas separam processo, espera do lock e duração total;
ações de navegação comuns também têm timings.

Resultados distinguem passed, failed, cached, skipped e interrupted. SIGINT/SIGTERM
encerram grupos de processos e deixam relatório. Reinício abrupto/SIGKILL pode deixar
um run como running; ele não é aceitação e sua retomada só reutiliza etapas completas
com entradas/saídas verificadas. Nunca converta ausência de relatório em aprovação.

## Fechamento

```bash
python tools/harness.py verify --full --video
python tools/iterate.py --label minha-entrega --goal 'Resultado observável' --video
python tools/iterate.py --review-only <execução>
```

Corrija os alvos afetados primeiro; depois congele fontes e execute o grafo completo.
Testes comportamentais completos rodam novamente; apenas importação/exportação válidas
podem ser reutilizadas. Filtros de caso/fixture/viewport não entram em `verify --full`.
O gate do CI exige scope full, cobertura completa, todas as tarefas e dez cenários
aprovados, incluindo a matriz. `--step-timeout` mantém o limite configurável de browser
(1.800 segundos por padrão); não reduz as asserções.

`iterate` acrescenta comparação e HTML/ZIP portátil; inspecione renders e vídeo e
registre notas. `--review-only` refaz a apresentação sem reexecutar testes.

Os self-tests do runner cobrem dependências, filtros, cache corrompido, retomada,
isolamento, processos interrompidos, workers, símbolos globais dos módulos Python,
divergência da main e distinção entre foco e aceitação completa.

O guard arquitetural registra separadamente a dívida já existente na main atual e
impede que ela cresça. Veja [architecture-guidelines.md](architecture-guidelines.md).
Verde não significa que essa dívida já foi eliminada, nem certifica diversão, áudio
ou desempenho em hardware.

## Autoria e compatibilidade — V04-DEV-02

`python tools/harness.py check --suite catalog,catalog-authoring` valida manifesto,
IDs, grafo/ramificações, traços registrados e bindings de arte.
`python tools/harness.py check --suite expedition-save,harness-core` cobre migração
da fixture original, identidade e proteção de gravações incompatíveis.
`python tools/harness.py replay --input <fixture-record.json>` aceita os envelopes
gerados por fixtures; arquivos antigos passam apenas pela migração explícita.
Os fingerprints incluem Resources em `content/**`, catálogo e serviços de sessão;
edições nesses contratos invalidam as tarefas dependentes, inclusive exports.
