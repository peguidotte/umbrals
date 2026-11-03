# V04-DEV-03 — próximas fronteiras de crescimento

Base de produto: main `6e1b2edd6333998c9523e91d2a67969730d5d7ed`, confirmada por preflight com fetch. O usuário autorizou implementar as cinco frentes com agentes GPT-6.1 Terra e entregar tudo na main. Esta nota é um plano e um checkpoint de retomada; não declara as implementações locais como integradas ou aprovadas.

## Objetivo e limites

Adicionar criaturas, poderes e itens com dados e comportamentos registrados; detectar estados inválidos nas fronteiras; reduzir a concentração dos coordenadores; manter saves compatíveis com adições comprovadamente seguras; diagnosticar e repetir tarefas do harness com evidências pequenas.

Preservar valores, ordem do RNG, UID/passiva/formas, cópias físicas, reservas/KO, captura explícita, iniciativa e políticas de informação. Não alterar a direção visual, a versão 0.3.0, os gates humanos ou Como jogar. Não duplicar estado autoritativo nem converter views em hosts do jogo.

## Ordem e responsáveis

1. **CI/harness** (`ci_harness`): identificar a falha remota, separar diagnóstico leve de mídia/builds, exibir trechos de erro, permitir repetição individual com dependências verificadas e manter a aceitação completa honesta.
2. **Modelos de domínio** (`typed_models`): Individual, CardInstance, BattleCommand e BattleEvent tipados, validação e DTOs com cópias independentes. Integrar os modelos nos produtores e nas fronteiras reais; não manter um segundo estado mutável.
3. **Coordenadores** (`battle_rules`, `ui_coordinator`): módulos coesos para ciclo de cartas, planejamento, avaliação, resolução e recompensas; apresentação de batalha, foco, entrada e escolha inicial fora de main. Um integrador por fachada. Novos módulos respeitam os limites do guard; a dívida residual deve ser medida e declarada.
4. **Conteúdo** (`content_resources`): Resources e manifestos ordenados para poderes, itens e encontros, catálogo isolado com consultas que retornam cópias, handlers explícitos de itens, CLI de autoria e validação de referências. Preservar o digest histórico quando a mudança for apenas de representação.
5. **Compatibilidade** (`save_compat`): registro de transições auditadas e comparação de manifesto para adições seguras. Preservar definições existentes, pools, rotas e ordem relevante; rejeitar alteração de balanceamento, remoção de IDs, identidade desconhecida e lineage inválida.

Modelos e contratos de catálogo precedem a integração de regras e migrações. As frentes podem desenvolver arquivos distintos em paralelo. O integrador final congela as fontes, executa os gates e revisa capturas/vídeo antes do push de produto.

## Aceitação por frente

- CI: causa observada documentada, diagnóstico pequeno acessível, export de fixture reproduzível em ambiente frio e limites entre fixture/produção comprovados. Nunca converter crash em sucesso nem repetir cegamente para esconder falha.
- Harness: `resume --from RUN --task NAME` força a tarefa selecionada, reutiliza apenas dependências bem-sucedidas e verificadas e informa cobertura focada; falhas/interrupções permanecem preservadas.
- Modelos: rejeição de dados malformados, propriedade de cartas e IDs duplicados; round trips e cópias sem alias; uso efetivo em planejamento, eventos e validação de restore.
- Regras/UI: manter os exemplos numéricos e cenários atuais; nenhuma dependência de host/main nos componentes; preview puro e estado único. Reduzir a baseline somente após comprovar as extrações.
- Conteúdo: manifesto determinístico, validação de custos/efeitos/referências/assets, autoria de novo item e catálogo de teste sem mutação global. Novos encontros não podem alterar implicitamente as rotas curadas.
- Saves/replays: fixture congelada de schema 2, transição aditiva permitida, mudanças incompatíveis rejeitadas sem modificar o estado ou sobrescrever o armazenamento; seed/RNG exatos e plano/ofertas preservados.

## Histórico da interrupção de infraestrutura

O ambiente `ccarenv_b64_Y2NhcmVudl9hYjgwMmJlNjdjNDQ4MTkxYTNlN2U1MGZlNmNjOTg1OQ` perdeu conectividade. O provedor informou `desired_phase=running`, `observed_phase=running`, `connectivity=offline`, sem capacidades executáveis. O usuário informou que não consegue reativá-lo agora.

Antes da queda, os agentes relataram implementações gravadas no workspace e verificações focadas:

- modelos: 12 checks;
- regras: 14.413 checks; fachada reduzida para aproximadamente 528 linhas significativas;
- save: 74 asserts;
- harness: 25 contratos e oito mutações detectadas;
- conteúdo: catálogo, isolamento de Resources e autoria focados passaram;
- UI: estado, grimório e expedição passaram; fluxo executou 437 checks sem falhas, mas o harness rejeitou a evidência por edição concorrente das fontes.

Esses resultados não substituem uma execução integrada com fontes congeladas. As alterações de produto estavam sem commit e não foram confirmadas na main. A persistência dos arquivos deve ser conferida ao recuperar o ambiente. Main ainda excedia a meta de tamanho após as extrações; não marcar essa dívida como eliminada.

## Diagnóstico remoto recuperado

A CI de `6e1b2ed`, run `41575037552`, falhou em `web-fixtures`. O job de recuperação `41629034165` / `125893577288` conseguiu ler o log do artefato antigo de 1,6 GB: durante o import frio da cópia de fixtures, Godot abortou ao importar `display.ttf` com **`free(): invalid size`**. O wrapper então lançou `RuntimeError: Godot export/import failed`.

Isso comprova um abort nativo durante importação; não comprova por si só a causa da corrupção de memória. Investigar concorrência de importação e confirmar qualquer mitigação no Godot 4.6.3 com reprodução e execução fria. Não tratar como erro de GDScript sem evidência.

Já estão na main os commits `b636b85` e `6072ce9`, que adicionam a ferramenta reutilizável `.github/workflows/recover-diagnostics.yml`. Ela aceita artefato/tarefa ou encontra a validação falha mais recente, recuperando apenas o diagnóstico selecionado no console.

## Retomada obrigatória

1. Restabelecer o ambiente e conferir `git status`, arquivos dos seis agentes e evidências locais; preservar tudo que estiver sem commit.
2. Buscar a main atual e incorporar por fast-forward os commits remotos de diagnóstico e esta nota, sem sobrescrever o trabalho local.
3. Conferir integração entre catálogo, modelos, regras, UI e compatibilidade; registrar as novas suítes de conteúdo e modelos no harness.
4. Reproduzir/corrigir o abort nativo de fixture com evidência; validar o diagnóstico leve e a repetição individual.
5. Atualizar guias e ratchet com métricas reais; executar primeiro os checks focados e depois o grafo completo com fontes congeladas e revisão renderizada.
6. Commitar e enviar todas as implementações autorizadas para a main atual. Conferir CI remota; não declarar sucesso remoto enquanto estiver pendente ou falha.

## Retomada e integração

O ambiente voltou, caiu novamente e foi recuperado. As implementações foram
confirmadas no filesystem e salvas no GitHub em `wip/architecture-v04-dev03`
(checkpoint inicial b234f88). Os commits remotos de diagnóstico e esta nota foram
incorporados por fast-forward antes da integração.

A revisão corrigiu rejeição tardia de cartas malformadas, adicionou schemas completos
aos comandos e tornou parâmetros/IDs dos efeitos parte da identidade. Migração é
exercitada com novas Resources reais em projeto isolado; a mochila também renderiza
um terceiro item usando dados próprios de teste. O guard reduz os tetos de main
para 1.115 e Rules para 528 linhas significativas; ainda há dívida explícita.

A aceitação integrada e revisão ficam em `artifacts/architecture-v03-verified-20261103/`.
Consulte o resultado efetivo em run.json e as observações em review-notes.md.
Esta referência de evidência não transforma um resultado pendente/falhado em sucesso.
