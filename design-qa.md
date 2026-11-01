# Design QA — V04-UX-05C

As seis melhorias foram aprovadas pelo usuário. Referência: terceira composição
em `ui/title-menu@1.0.0`; novas camadas de bosque/logo com proveniência no catálogo.
A imagem de referência é conceito aprovado; os caminhos abaixo são capturas do
executável, não imagens geradas.

- Pacote entregue: `7307bbbccb4e27dcbe588fc759818b78fb47dea5f7cf28ff34bee3a88f29576e`.
- Abertura final/vertical/reação: `test-results/V04-UX-05C-hosted-adapter/`.
- Jogar com save/texto mobile: `test-results/V04-UX-05C-typography-verified/`.
- Foco, hover, pressionado, ultrawide, tablet, texto ampliado, movimento reduzido:
  `test-results/V04-UX-05C-final/`. Os hashes e complementos estão na
  [nota da fatia](docs/title-menu-v04-05c.md).

Revisão: arte dos três poderes/cartas preservada; logo limpa; botão focado com
contorno chanfrado e losango; bosque uniforme nas margens; comandos sem colisões
nos formatos capturados. Vertical mantém cartas e comandos em grupos próprios.
Jogar usa o retrato e HP do checkpoint real, exibindo a próxima parada. Corrigidos
caption sob a moldura, chanfro em largura inicial estreita, fonte pequena no
celular e efeitos desenhados atrás do fundo. Frames do vídeo final foram abertos
para conferir flutuação e reação, com a camada de fitas/faíscas visível.

Verificado: 245 checagens nativas, 135 de fluxo/apresentação, complemento de 18
após o texto de Jogar, validação de 58 releases/126 arquivos e abertura/entrada
no adaptador Site. Não foi repetida a suíte completa, por instrução do usuário.
Esses números cobrem etapas distintas; não são uma única execução integral no
último pacote. Capturas de movimento reduzido da passagem funcional são idênticas.
A nova ordem de camadas tem captura própria no adaptador final.

Limites: toque emulado, Chromium com WebGL por software, sem telefone/controle
físicos, escuta subjetiva, leitor de tela ou regressão completa de batalha nesta
fatia. Aprovação estética final continua humana. Não há nova promessa de
identidade pixel a pixel para estados animados/adaptativos.

---

Registro histórico preservado:

# Design QA — V04-UX-05B, tela inicial

- Source visual truth: `assets/ui/title-menu/versions/1.0.0/texture.png`, geração `exec-c4063f14-d989-4041-b562-a3b96fe10f92`, terceira revisão explicitamente escolhida pelo usuário.
- Implementation screenshot: `test-results/V04-UX-05B-menu-final/menu-default.png`.
- Viewport / CSS: 1672×941, deviceScaleFactor 1. Fonte e captura: 1672×941 pixels. Sem redimensionar as imagens para a comparação.
- Estado: abertura, foco em Jogar, efeito congelado pelo modo oficial de captura. A animação é avaliada separadamente; modifica intencionalmente os pixels.
- Full-view comparison: `test-results/V04-UX-05B-menu-final/full-comparison.png`, fonte à esquerda e jogo à direita no mesmo arquivo. Comparação aberta e inspecionada.
- Focused comparisons: `menu-comparison.png` e `cards-comparison.png`, no mesmo diretório; foco tipográfico e nos materiais dos botões, e escala/arte das cartas. O render inteiro e o recorte de menu foram inspecionados em conjunto com a referência.

## Findings e histórico da comparação

1. **P2, corrigido — amostragem horizontal do cenário.** O primeiro ajuste pela proporção literal do PNG criou posicionamento fracionário dentro da referência lógica 1600×900. A metade direita amostrava algumas colunas vizinhas; 634231 pixels diferiam. Evidência anterior preservada em `test-results/V04-UX-05B-title-first/comparison.png`. A composição agora usa a referência lógica do jogo; controles usam regiões normalizadas da arte. O estado congelado usa o material padrão, sem o shader de movimento.
2. **Verificação posterior:** `test-results/V04-UX-05B-menu-final/reference-comparison.json` registra **zero pixels diferentes** no enquadramento especificado. O adaptador da hospedagem também foi aberto no navegador e registrou zero diferenças em `test-results/V04-UX-05B-hosted-adapter/comparison.json`. Essa medição certifica identidade do raster nesse estado; não é nota de beleza ou compreensão humana.
3. Não restam diferenças P0/P1/P2 observadas na abertura comparada. Estados de foco e ampliação têm alterações intencionais de apresentação.

## Superfícies de fidelidade

- **Tipografia:** logo e rótulos são os pixels da arte aprovada, com família, peso, espaçamento, contornos e quebras preservados. Não foi escolhida uma fonte aproximada para redesenhá-los. Os Controls têm nomes e texto semântico próprios; a opção de texto ampliado aumenta o recorte original em 12%.
- **Espaçamento/layout:** quatro áreas interativas acompanham os botões da composição. O jogo preserva o enquadramento de referência; formatos mais largos/altos mostram margens. Capturas de foco, toque 844×390 e texto ampliado foram abertas e inspecionadas, sem cortes ou sobreposição dos quatro comandos.
- **Cores/tokens:** branco/marfim, lilás e índigo da logo e dos controles são preservados. O brilho laranja das cartas e o cenário noturno não foram reinterpretados. O foco adicional tem contorno, além de cor.
- **Imagens:** o PNG original está intacto, com SHA-256 no manifesto. Nenhum logo, retrato ou ícone foi substituído por SVG, emoji, fonte ou desenho aproximado. A imagem é a fonte visual do menu real do Godot, com botões reais sobre suas regiões.
- **Conteúdo:** somente UMBRAL e Jogar, Grimório, Opções, Como jogar na abertura. Nova/Continuar/Treino ficam no submenu de Jogar; créditos continuam disponíveis pelo guia. O Grimório existente continua com seu conteúdo anterior, sem atribuir a esta fatia uma reformulação do códex inteiro.

## Interações e movimento efetivamente verificados

`tools/title_browser_review.py --video` concluiu 22 verificações, sem erros de console/página: quatro comandos, foco/volta, submenu, cancelamento de vínculo, toque emulado e efeito ao clicar na carta. Dois PNGs de movimento reduzido permaneceram idênticos após 300 ms. O teste nativo cobre RNG/save ao alternar a preferência.

`test-results/V04-UX-05B-touch-effect/report.json` confirma um toque emulado na carta, efeito disparado uma vez, permanência no menu e conteúdo do localStorage inalterado. Capturas em tempos distintos mostram mudança visual. `test-results/V04-UX-05B-press-review/` verifica Jogar pressionado, sem render de fonte/botão genérico sobre a arte.

O efeito consiste em refração suave, reflexos, sete faíscas limitadas e um pulso curto de energia ao tocar. Não é uma animação de poses independentes das criaturas/cartas. A preferência de movimento reduzido remove imediatamente o shader e zera seus tempos. Os efeitos não usam o RNG da partida.

Vídeo real: `test-results/V04-UX-05B-menu-final/video/`; amostras de quadros inspecionadas. `card-effect-demo.webm` é um trecho de 20 segundos reencodificado do vídeo original. A galeria `index.html` foi aberta por HTTP local; cinco imagens carregaram, o vídeo reproduziu e não houve erro de página (`gallery-check.json`).

## Open questions / limites

Não há decisão pendente para implementar a abertura escolhida. Não foram testados telefone físico, controle físico, leitor de tela ou GPU real. A identidade de pixels refere-se ao estado/viewport acima; outras proporções usam o enquadramento adaptativo e o movimento produz mudanças intencionais. Localização para outros idiomas e reformulação dos submenus não fazem parte desta fatia.

## Implementation checklist

- [x] Usar a terceira revisão exata e preservar o original/manifesto.
- [x] Quatro botões reais, nomes acessíveis, teclado/toque e volta.
- [x] Reunir escolhas de expedição dentro de Jogar, preservando confirmação/save.
- [x] Efeito nas cartas com movimento reduzido aplicado aos nós atuais.
- [x] Captura e comparação conjunta da referência e do jogo.
- [x] Corrigir a divergência de amostragem e conferir o novo render.

## Follow-up polish

P3: fora de 16:9, as margens mostram o bosque existente; o foco usa um contorno funcional simples. Nenhum P3 impede esta abertura. A legibilidade e o desempenho em aparelho físico ainda dependem de verificação nessa plataforma; testes automáticos não certificam esses resultados.

Validação funcional consolidada por suítes: `artifacts/V04-UX-05B-closure-20261101T005614768531Z/closure-report.json`. As duas tentativas integrais permanecem failed; não se afirma um passe integral do orquestrador.

final result: passed
