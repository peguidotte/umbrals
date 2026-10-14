# Revisão visual — Umbral 0.3

Revisão de renders atuais do jogo, em Chromium com WebGL por software. A captura completa `test-results/v0.3-flow-3/` executou 627 verificações, venceu uma run com captura/evolução e completou os cinco formatos de tela. Esse registro precede os ajustes finais de disposição inicial das cartas e encerramento nativo; a execução final do harness guarda a evidência consolidada em `artifacts/`.

Foram inspecionados menu, combate inicial, boss evoluído, opções acima de cartas selecionadas, inspeção, captura, evolução e vitória, além de combate com texto ampliado em 1280×720/1024×768 e ultrawide 2560×1080. As imagens originais foram vistas; a revisão de movimento usa também frames extraídos do vídeo entre 80–82 segundos, sem editar assets do jogo.

## Decisões observadas

- **Entrada:** título, ação inicial com foco e lista curta sobre uma floresta escura. A arte do bosque integra o cenário à arena; o texto continua nativo. O menu da v0.2 não existia.
- **Hierarquia:** protagonistas à esquerda e adversário à direita; fôlego/rodada no alto, intenção junto ao adversário, escolhas e energia junto à mão. O HUD ocupa menos espaço que os painéis laterais anteriores.
- **Leitura:** nomes e números das cartas são maiores. A prévia explicita dano/proteção/cura e fôlego resultante. Detalhes de trait/passiva estão na inspeção e recompensas. Terceiro vínculo foi elevado para não tocar na prévia.
- **Estados:** seleção tem marca de confirmação e elevação; foco tem contorno/glyph. Erro de energia comunica o limite. Texto ampliado preserva os alvos nos cinco formatos; 4:3 expande a arena verticalmente.
- **Camadas:** opções e inspeção cobrem cartas elevadas após corrigir o z-index do modal. Texto escuro no botão principal mantém o contraste ao receber foco.
- **Recompensas:** captura mostra o indivíduo/passiva sorteado; evolução mostra trait, passiva preservada e assinatura antes da escolha. Substituição exige seleção explícita e permite cancelar.
- **Movimento:** o vídeo mostrou cartas respondendo à seleção, indicação de conjuração, números de dano/queima/revide e vida retornando a um estado legível. O impacto é breve; o HUD fica estável enquanto a arena pode tremer. A captura estática de conjuração pode já mostrar o estado resolvido; o vídeo registra o movimento.

O vídeo revelou que cartas recém-criadas começavam empilhadas antes de abrir o leque. O layout inicial agora é aplicado imediatamente, e tweens ficam para foco/seleção. Efeitos não redesenham o canvas quando em repouso. O export Linux foi executado e encerrou sem erros depois de liberar explicitamente os players de áudio antes do fechamento.

## Aprovação e limites

Direção aprovada por revisão do agente para esta versão do MVP: floresta em azul/verde, pergaminho, ouro antigo e criaturas vetoriais originais. `assets/world/clearing.png` passou QA de tamanho/formato e foi inspecionado em contexto; os 37 assets fonte têm origem e hash registrados. Não houve publicação comercial nem validação de regras da Steam nesta tarefa.

Os controles e títulos visíveis passaram nos gates citados; isso não é auditoria completa de acessibilidade. Informação secundária e quatro ofertas simultâneas ainda são densas. A leitura à distância, áudio, performance e controle físico pedem playtest em hardware. A arte vetorial tem menos detalhe que a floresta; uma família de criaturas ilustradas é uma hipótese para uma próxima direção, com referência compartilhada e revisão no jogo. Não há promessa de melhoria estética monotônica ou prova automática de diversão.
