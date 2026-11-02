# V04-UX-05F — retornar à ficha de origem no grimório

Problema reproduzido: abrir Bola de fogo pela ficha de Brasa e pressionar Esc
fechava todo o grimório. Consultar uma informação relacionada fazia o jogador
perder o ponto de origem.

Agora o botão Voltar, Esc e B percorrem o histórico de links entre registros.
Umbral → evolução → poder retorna primeiro à evolução, depois à forma base;
só na raiz fecha o grimório. Categoria, seleção, página, rolagem do painel e
foco semântico são restaurados. O tooltip/nome acessível de Voltar indica o
registro de destino. A escolha explícita de uma categoria inicia nova consulta.
Não houve alteração das artes ou da composição aprovada.

O histórico pertence à instância de apresentação do códex e não é persistido.
A stack principal continua dona da tela; consome primeiro o retorno interno
quando a tela superior é o grimório. Não se altera perfil, conhecimento,
checkpoint, regras ou RNG. Uma nova navegação cancela restaurações assíncronas
pendentes, evitando recuperar foco de um contexto que já foi abandonado.

Validação focada, com armazenamento isolado:

- `tests/codex_navigation_test.gd`: antes da correção, falha no retorno do poder
  (três verificações executadas, uma falha). Após a correção, 24 verificações
  passaram tanto headless quanto no Godot com render nativo. Exercita teclado,
  botão Voltar e eventos de B do controle, dois níveis de histórico, página 2,
  rolagem real, foco, saída na raiz e cancelamento do histórico ao trocar de aba.
- `tests/gold_ui_test.gd`: 37 verificações headless passaram, preservando o fluxo
  de menu, categorias, descoberta, consulta e retorno à batalha.
- Capturas reais do registro de origem, do poder e do retorno foram inspecionadas
  em `test-results/codex-navigation/`. O teste compara a rolagem numericamente e
  confirma que estado da partida, conhecimento, checkpoint e RNG não mudaram.
- O runner focado `tools/title_checks.py` inclui a nova regressão para execuções
  futuras. A suíte completa de combate não foi executada. Controle físico não
  foi testado; os eventos de controle foram injetados no Godot.

Versão 0.3.0 e marco 0.4 permanecem. Próxima revisão pode avaliar outros pontos
de navegação, sem reabrir a direção artística aprovada.

Continuação em [V04-UX-05G](codex-stories-v04-05g.md): o histórico inclui a aba
História/Descrição ou Poderes/Efeito. Após a reorganização da ficha, a regressão
de navegação passou em 28 verificações e o fluxo existente em 38.
