# V04-UX-05L — recomposição portrait; acabamento bloqueado por referência

A revisão de Pedro preserva a floresta ultrawide de 05K e rejeita três pontos: Brasa pixelado sobre pintura, Foli sentado/desperto e excesso de céu no portrait. Sprites correspondentes ao runtime não satisfazem o acabamento ilustrado da seção 3 da spec.

## Escopo permitido e dependências

Preflight com fetch: main `f29752cac7d6525865091896a1466eb65a490c9c`, base local `b856b143234590db3613880521fd4dea9c1c109a`, sem atraso e árvore inicialmente limpa. A spec `libfile_680ef2a885208191806d7111558f4ff4` foi lida integralmente nesta revisão.

A identidade do menu oficial permanece `libfile_f55fcf044ed081919dbe9c40c82e07ea`, conteúdo `file_000000000b688212925d7e178f878504`, nome `menu-umbral-logo-integrada-lonlon-v2.png`. A leitura retornou metadados/texto e ponteiro de imagem; não bytes locais. A preparação oficial selecionou exatamente essa identidade, mas o helper oficial de transferência retornou `download failed`. Nenhum PNG foi instalado. Não houve tentativa de contornar restrição ou buscar outra rota após essa falha. O anexo direto anterior continua referência visível na conversa; não é um arquivo local disponível para overlay ou prancha exata.

A referência revisada do **Brasa inicial** e sua aprovação não foram confirmadas. O acervo do repositório tem somente o final com três caudas. `brasa-arvore-quatro-formas-v2.png` (`libfile_299871807a048191ba2d69ae8bb42115`) contém evoluções propostas, não aprovação recente. Busca de contexto pessoal está indisponível; buscas na Library não forneceram uma nova aprovação verificável. Foi solicitada a identidade exata e a evidência de aprovação. Conforme a condição do pedido, **nenhuma nova arte foi produzida antes dessa confirmação**. O sprite pixelado não recebeu filtro ou upscale para simular detalhe.

## Correção independente implementada

O portrait usa a região abaixo da interface para distribuir fogo na parte superior, Lonlon no meio e Foli/Nisca na base. Pivôs e texturas canônicas permanecem; personagens recebem escala uniforme. Os suportes acompanham cada ator. A imagem existente é reenquadrada uniformemente a partir do horizonte/área disponível; retratos mais largos usam o vale paisagem existente. Não há estiramento, nova arte de cenário ou recomposição pintada inventada.

Quando os rótulos cabem, a navegação usa duas colunas. No Web, a terceira ação fica centralizada na segunda linha; o nativo mantém quatro ações. Texto ampliado recorre à coluna quando necessário. A redistribuição não altera saves, catálogo, regras, overlays ou escolhas de inicial. Desktop e ultrawide conservam o enquadramento e a floresta de 05K.

## Trabalho de arte ainda pendente

- Brasa inicial ilustrado, com referência revisada e aprovação verificáveis.
- Foli descansando/dormindo, com despertar, espreguiçar e retorno desenhados.
- Lonlon com pata estendida e poses autoradas de empurrar, recuperar e reagir ao drible.
- Acabamento e clips específicos dos quatro atores; as deformações de sprites atuais continuam provisórias.

Esta revisão não afirma que corrigiu essas poses ou que obteve aceite artístico. O clipe da candidata deve mostrar o estado real dos quatro atores, identificando a limitação.

## Evidências e validação

As primeiras capturas em `test-results/title-portrait-05l-layouts` revelaram Nisca cortando pontas de espinhos à direita e pouco espaço cênico em 320×568; motivaram o recuo/escala de Nisca e o reflow de navegação. Também foi identificado um galho solto em retratos mais largos: o suporte de Brasa passou a chegar à borda esquerda com escala uniforme, sem transformar o corpo. São evidências intermediárias, não finais. O foco nativo/build tem relatórios próprios, sem herdar o resultado integral de 05K. As capturas finais e o novo ensaio integral serão identificados por seus manifests reais.

Windows/DPI/hardware não foram executados nesta revisão. A exportação anterior em Linux não prova execução da candidata nova em Windows. Comparação exata referência oficial versus candidata permanece dependente dos bytes autorizados da referência; comparações antes/depois devem ser rotuladas assim. Sem push, merge, deploy ou reativação de Actions. Produto 0.3.0.

A verificação real de foco detectou perda de Opções no retorno portrait → wide: a linha era escondida antes de capturar o foco. A ordem foi corrigida e quatro transições foram acrescentadas ao cenário oficial do título, sem remover asserções existentes. O primeiro relatório parcial foi preservado.

O foco final `title-portrait-05l-final` passou arquitetura, título nativo (48), export Web e catálogo empacotado (5), com fontes inalteradas. A verificação real de teclado manteve Opções focada e visível em 390×844 → 1600×900 → 320×568 → 800×900; `focus-resize-final.json` registra as quatro transições. Os PNGs de 1600×900, 1440×900, 2560×1080 e 5120×1440 são byte a byte iguais aos anteriores de 05K (`wide-preservation.json`). As capturas do novo apoio de Brasa e o portrait foram abertos e inspecionados. Esses resultados não aprovam a arte pendente.
