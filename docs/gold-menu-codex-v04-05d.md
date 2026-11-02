# V04-UX-05D — menu e grimório dourados

O usuário escolheu a dupla de menu centralizado e grimório dourado, com os sprites atuais de Brasa/Musgo e suas evoluções. Essa escolha substitui a direção violeta da abertura de 05B/05C, sem reformular o HUD de batalha. Produto continua 0.3.0.

## Entrega

- Menu com floresta em camada própria, título nativo, comandos centrais, sprites originais em atlas e molduras douradas. Jogar preserva o submenu Continuar/Nova/Treino e o save existente. Opções, ajuda, créditos e saída continuam controles reais.
- Grimório com categorias Umbrals, Poderes, Passivas e Itens, paginação, ficha selecionada e links para poderes/evolução. Todos os seres, inclusive os encontrados como oponentes, ficam na categoria Umbrals. Não há categoria de monstros.
- Descobertas aditivas em `umbral.codex.v1`, separado do checkpoint e das estatísticas. Registra formas, poderes conhecidos, passivas e itens possuídos; os Umbrals oponentes são registrados ao encontrá-los. Evolução só revela sua forma quando ela é observada. Reabrir não altera regras, RNG, cartas ou checkpoint.
- Migração aproveita somente a equipe e o encontro do checkpoint existente, sem inventar histórico de partidas anteriores. Sem checkpoint ou registro, o grimório começa desconhecido.
- O menu e o grimório usam texto nativo, sprites existentes e um novo fundo original `world/gold-forest@1.0.0`, com proveniência e pin explícitos. A moldura é desenhada como decoração nativa. Não se usa uma captura completa como interface.

## Validação proporcional

Por solicitação explícita do usuário, não executar a suíte integrada de combate, simulações ou mutações. Validar somente consumidores de assets, menu/save, navegação do grimório e persistência da descoberta.

- `python tools/title_checks.py`: 247 verificações, zero falhas (216 consumidor de assets, 28 menu/save/áudio, três startup).
- `python tools/assets.py validate --base-ref origin/main`: 59 releases e 127 arquivos, zero falhas; releases antigos preservados.
- `tests/gold_ui_test.gd`: 45 verificações, zero falhas; navegação real por eventos de teclado no Godot, descoberta sem modificar estado/RNG, roundtrip de persistência, categorias/paginação/poder relacionado, retorno à batalha, evolução e capturas. Executado com dados de usuário isolados. A captura nativa executou 45 verificações; a repetição headless após ajuste do encerramento executou 37, sem erros de limpeza. Resultado final e imagens em `test-results/gold-ui/`.
- Capturas revisadas de menu, grimório desconhecido, descoberto, poder, evolução, 1280×720 e 1024×768. O painel de detalhes tem rolagem para conteúdo/texto maior.

Não se afirma equivalência pixel a pixel ao conceito gerado, teste com controle físico, aprovação estética humana, nova exportação/publicação ou regressão completa de gameplay. A implementação usa sprites originais e UI nativa; o conceito continua referência de composição e paleta.

## Revisão de fidelidade após feedback

A primeira entrega foi simplificada demais frente ao conceito escolhido. A revisão
amplia o título e a criatura da ficha, substitui a tipografia por Cormorant Garamond
(com licença OFL incluída), acrescenta uma moldura botânica transparente original,
cenário nas cartas e miniaturas maiores de poderes. Retira a caixa externa da ficha
e escurece o fundo nas áreas de leitura. Sprites, descobertas e rotas não mudam.

Validação focada da revisão: 286 verificações do runner de abertura/códex passaram;
61 releases e 130 arquivos conferidos sem falhas. Capturas nativas de menu,
descobertas, poder, evolução e texto ampliado foram revisadas em
`test-results/gold-ui/`; a entrega anterior foi preservada em
`test-results/gold-ui-before-polish/`. Não houve suíte completa de combate.

## V04-UX-05E — montagem sobre as artes aprovadas

O usuário rejeitou novamente a aproximação e pediu a composição aprovada como
gabarito. A abertura agora particiona a arte aprovada em faixas de cenário/marca
e seis placas individuais consumidas por botões Godot reais, nas coordenadas
1672×941 da fonte. Não há redesenho do logotipo ou das legendas fixas da abertura.
O grimório usa um template vazio derivado da referência, os retratos e ornamentos
do atlas aprovado, com seleção, categorias, registros e links operando no modelo
real. Elementos gráficos fixos preservam seus pixels de origem; contagens,
registros não ilustrados e descrições variáveis continuam ligados ao catálogo.
A opção de texto ampliado sobrepõe legendas nativas maiores aos comandos.

A evolução passa a viver na ficha da linhagem em vez de ocupar outra carta na
galeria principal. O catálogo navegável contém quatro linhagens e três Umbrals
de encontro; por isso a contagem real não copia os três exemplos da imagem.
Essa alteração só organiza a apresentação; não cria descobertas em produção.

`ui/gold-approved@1.0.0` preserva os PNGs originais da referência e dos templates,
com proveniência por arquivo e regiões aplicadas somente em runtime. As artes
aprovadas são usadas para marca, molduras, retratos e placas fixas. Cada área
interativa tem Button, nome acessível, foco e callback próprios. O registro
persistente de descobertas e as regras de batalha não foram alterados.

Validação focada: 291 verificações do runner de abertura/códex passaram; 45
verificações com render nativo e teclado passaram. Assets: 62 releases e 135
arquivos íntegros. Capturas reais de menu, Brasa, Musgo e entrada desconhecida
em `test-results/gold-reference/`. As capturas de comparação usam um perfil de
fixture isolado com duas linhagens e Ignivar conhecidos, apenas Bola de fogo
revelada. Esse perfil não é salvo no armazenamento do jogador.

A comparação em `compare.html` mostra referência e render no mesmo tamanho.
O raster do menu é conferido separadamente, sem transformar diferença de pixels
em nota de beleza. Não se afirma igualdade dos dados do catálogo com o texto
ilustrativo do mockup nem identidade de raster entre resoluções diferentes.
