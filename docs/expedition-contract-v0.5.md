# V05-RUN-01 / V05-SAVE-02 — contrato de implementação

Defaults de protótipo adotados por delegação em 29/10/2026. Implementação integrada e validada localmente; produto 0.3.0, sem encerrar os critérios humanos de 0.4.

- Uma expedição contém a fachada de batalha; o time e as cartas têm um único
  dono de estado, sem cópias divergentes no mapa. Perfil/estatísticas separados.
- Grafo curto inicial fixo: `clearing` (combate/template 0) → `thicket`
  (combate/template 1) **ou** `spring` (descanso) → `boss` (template 2).
  Não promete geração procedural de biomas nesta fatia. Semente governa os
  sorteios existentes; consultar mapa não consome RNG.
- A trilha oferece a recompensa normal de captura/evolução. O descanso cura
  25% do HP máximo de cada integrante vivo (arredondado para cima), limitado ao máximo, sem reanimar,
  gerar recompensa ou reabastecer itens. Custo: abrir mão daquele combate e
  sua recompensa. Números sujeitos a playtest; nenhum ganho permanente.
- Nós exigem confirmação, só podem concluir uma vez e a alternativa não
  escolhida fica inacessível. Voltar/cancelar não escolhe ou sorteia.
- `Expedition` (`scripts/expedition/expedition.gd`) expõe `battle` (Rules),
  `phase` (`map/combat/reward/victory/defeat`), `current_node_id` e:
  `new_run(seed, mode, starter)`, `public_state()`, `choose_node(id) -> bool`,
  `settle_battle() -> void`, `choose_reward(index, replace_uid=-1,
  capture_slot=-2) -> bool`, `snapshot() -> Dictionary`,
  `restore(data: Dictionary) -> bool`. Restore é atômico e valida schema/IDs.
- `public_state()` entrega cópias: `phase`, `seed` (texto), `biome`,
  `current_node_id`, `nodes` (array na ordem clearing/thicket/spring/boss),
  `party`, `inventory`. Cada nó: `id`, `title`, `kind` (`battle/rest/boss`),
  `description`, `available`, `completed`, `locked`, `encounter_id` (ID estável),
  `next` (array de IDs). Não inclui fila inimiga privada ou ordem da compra.
- Rules preserva modo de treino sequencial por padrão. O modo expedição usa
  encontros por ID e devolve a escolha de recompensa ao mapa; não inicia o
  próximo combate implicitamente. Adaptar sem quebrar regressões de batalha.
- `ExpeditionMap` (`scripts/ui/expedition_map.gd`) é uma apresentação pura
  com `populate(snapshot, text_scale, selected_id="")`, sinais `node_requested(id)`,
  `selection_changed(id)`,
  `pause_requested`, `formation_requested`, `control_created(control,id)`. Registra botões `map.node.ID`,
  `map.confirm`, `map.pause`, `map.formation`. Selecionar inspeciona; Confirmar solicita entrada. A seleção visual sobrevive
  à pausa e às opções; IDs que deixaram de estar acessíveis usam o padrão atual.
  Anchors/containers, rolagem, foco e opção de texto ampliado.
- `RunSave` (`scripts/expedition/run_save.gd`) aceita snapshots opacos do
  controlador: `save(snapshot)->bool`, `load_snapshot()->Dictionary`,
  `clear()->bool`. Envelope versionado, integridade e recuperação; storage
  separado de preferências/estatísticas. Paths/keys opcionais no construtor
  para fixtures. O controlador valida o conteúdo antes de aplicá-lo.
- Checkpoint após entrada confirmada, resolução de rodada e recompensa/rest.
  Persistir o estado exato do combate estável (incluindo RNG como strings de
  64 bits, mão, zonas e intenção comprometida); nunca salvar uma meia animação.
  Ao retomar, não sortear de novo. Comandos não confirmados podem ser limpos,
  mantendo mão, alvo padrão e RNG. Não prometer retomada de animação.
- Menu: Expedição é o fluxo principal; Treino de batalha mantém o percurso
  curto anterior, explicitamente separado. Continuar carrega o checkpoint
  validado. Treino não sobrescreve a expedição salva. Novo jogo não apaga um
  checkpoint existente antes de confirmação. Resultado final não deve repetir
  estatísticas após reload.

Divisão: agente de regras/expedição mantém Rules + controlador + testes próprios;
agente UI mantém o componente de mapa; agente de save mantém envelope/storage
e testes; agente de validação adapta os percursos de treino e adiciona QA da
expedição. O integrador mantém `main.gd`, contratos e execução final.

## Integridade observada na integração

A substituição confirmada de uma expedição aposenta também o backup antigo antes
do primeiro checkpoint novo. Se o armazenamento não permitir essa operação,
a nova run pode ser jogada sem autosave, com aviso explícito, preservando o
registro anterior. Treino não apaga ou sobrescreve esse registro.

Resultados usam um identificador próprio por expedição e um diário limitado no
perfil para contar uma conclusão uma única vez. Um checkpoint cujo ID já foi
concluído não reabre a batalha. Web escreve e verifica por leitura síncrona;
a retomada não confia somente no retorno de um booleano da ponte JavaScript.
