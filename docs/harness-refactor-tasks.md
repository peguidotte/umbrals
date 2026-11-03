# Lead time de desenvolvimento

Ordem autorizada e contratos de entrega:

1. Catálogo por instância e planejador limitado a combinações de até três cartas.
2. Snapshot completo validado e replay determinístico de comandos.
3. Runner com registro único, dependências, filtros de suíte/caso e resultados isolados.
4. Cenários de navegador independentes e fixtures numa entrada exclusiva de testes.
5. Plano incremental, cache de build por entradas/ferramentas e retomada verificável.
6. Paralelismo headless coordenado, métricas por tarefa/ação e relatório de cobertura.
7. Integração dos wrappers/CI, guias, testes do próprio harness e aceitação completa.

Execuções focadas são evidência parcial. A aprovação de entrega exige a lista completa
de tarefas e formatos, sem converter etapas omitidas/interrompidas em aprovação.

Implementação entregue em cada etapa:

| Etapa | Contrato concreto |
|---|---|
| 1 | `game_catalog.gd`, dependência por run em regras/views e `selection_planner.gd` |
| 2 | `run_snapshot.gd`, `snapshot_records.gd`, `run_replay.gd` e equivalência após recompensa |
| 3 | `harness.py`, registro/dependências, filtros confirmados e outputs/user data por tarefa |
| 4 | Oito cenários, sete fixtures validadas, boot test-only e comparação do PCK de produção |
| 5 | `plan --changed`, fingerprints de entradas/ferramentas/saídas, `resume` e `--fresh` |
| 6 | Workers limitados, locks, processo/espera por tarefa, ações de browser e cobertura explícita |
| 7 | Wrappers/CI no mesmo registro, self-tests do harness e guias em `docs/harness.md` |

A evidência de fechamento fica no `run.json`/`review.html` da iteração de entrega.
Os testes focados e tentativas com falha permanecem preservados; só `coverage.complete`
com fontes congeladas representa a aceitação automática completa.
