# QA visual — V05-CARD-06 (histórico CARD-05 preservado)

final result: blocked

## Revisão atual — tipografia e centro (CARD-06)

O título selecionado perdia seu centro porque a reserva para alvo/custo
reduzia apenas o lado direito. A reserva agora é simétrica. As placas usam
Cormorant Garamond Bold 700 já existente no projeto; fonte, métricas e desenho
estão alinhados. O eixo usa tag OpenType numérica, pois `wght` textual foi
ignorado nesta versão do motor e renderizou Light no primeiro ciclo.

O primeiro ciclo tecnicamente verde em `card-type-center-browser/` foi
rejeitado visualmente. O ciclo Bold em `card-type-bold-browser/` passou
759 checks; a inspeção motivou preservar a fonte anterior nos indicadores
pequenos. `card-type-final-build/` passou 51 checks nativos, exportação e
catálogo empacotado. A matriz final `artifacts/card-type-final-manual/` tem
12 capturas inspecionadas, Foli/Lonlon em repouso/seleção, 720p/1080p e texto
ampliado; nomes completos no destaque, custo e alvo legíveis, sem clipping
do título na placa. Repouso continua com oclusão por cartas vizinhas.

O anexo continua visível no chat, mas o original não está disponível como
arquivo local para comparação conjunta ou identificação exata da fonte.
Não se declara fidelidade artística nem aprovação subjetiva. Molduras e
catálogo parcial continuam pendentes. Fechamento técnico integral atual:
`artifacts/card-type-final-acceptance/`; verificar seu resultado efetivo.
Detalhes: `docs/assets/card-assets-type-v05-card06.md`.

## Fonte e implementação

- Fonte visual: anexo aprovado de Pedro, `Identidade do Umbral, poder em ação`,
  1280 × 720, visível na conversa. Não há caminho local verificável para os
  bytes originais neste executor. O parent informou acesso em seu workspace.
- Implementação: combate real dos boots `motion_moss` e `motion_dew`, com a
  prévia optativa, cartas possuídas e entradas reais do mouse/opções.
- Viewports e PNGs: 1280 × 720 e 1920 × 1080; CSS, backing e leitura da GPU
  coincidem em DPR 1. Não foi aplicado redimensionamento posterior.
- Estados: mão sem seleção, Lâminas de folhagem selecionada e Gota serena
  selecionada; texto normal/ampliado. No fixture aquático, Lonlon é o alvo
  real de sua própria cura; a pintura fixa mostra Foli.

## Evidência aberta e inspecionada

- `artifacts/card-fan-pilot-readable/`: 12 PNGs e snapshots. Exemplo Foli final
  para área: `foli-selected-1920x1080-large.png`. Mãos sem seleção e Foli não
  usam o rótulo de alvo individual alterado na etapa seguinte.
- `artifacts/card-fan-pilot-marker/`: quatro novos PNGs de Lonlon após o último
  deslocamento do rótulo; exemplos `lonlon-selected-1280x720.png` e
  `lonlon-selected-1920x1080-large.png`.
- `captures.json` em cada pasta identifica estado, hora e resolução. O
  inventário de revisão adiciona SHA-256 e a diferença de fonte entre etapas.
- Não foi criada entrada conjunta original/render nem comparação de regiões
  do original: falta o arquivo da fonte. Visualizações separadas do anexo no
  chat e do jogo não são apresentadas como comparação lado a lado.

## Histórico das correções

1. P1: mão reta e cópia central. Corrigido com leque dos botões reais,
   crescimento da própria carta e remoção da projeção da árvore de combate.
2. P1: cliques sobrepostos divergiam da ordem visual e animação podia deslocar
   a área de release. Corrigidos irmãos/índices estáveis, seleção em press e
   destaque separado do hover. `card-fan-stable-focus/`: 750 checks Web.
3. P2: reorganização inicial encostou rótulos de campo. Grupos/escala ajustados,
   fontes compensadas; conferidos nas duas resoluções e nos dois tamanhos.
4. P2: retrato/área encobria o custo. Custo agora é pintado por último. O dígito
   1 está visível nas capturas Foli/área e Lonlon/retrato.
5. P2: aviso longo com texto ampliado aumentava a largura sobre o HP inimigo.
   Aviso agora quebra em até duas linhas no corredor; capturas Foli ampliadas
   em `card-fan-pilot-readable/` preservam o texto e liberam o HP.
6. P2: rótulo do destinatário encobria o sinal azul. Separação vertical
   conferida nos quatro PNGs de `card-fan-pilot-marker/`; nome, sinal e custo
   permanecem simultaneamente visíveis.
7. P2: vídeo de Conjurar mostrou a carta ampliada encobrindo projéteis.
   Destaque agora recolhe enquanto a rodada executa; seleção/alvos permanecem
   na mão, bloqueados para entrada. Duas capturas reais em
   `artifacts/card-fan-cast-clear/tasks/browser.cards/card-casting-clear-lane*.png`
   mostram campo livre e `busy=true`, seis escalas 1 e nenhum destaque grande.
   O cenário passou 759 checks. A tentativa integral anterior foi interrompida
   para essa correção e fica preservada, sem qualificá-la como aprovação.

## Superfícies de fidelidade

| Superfície | Observação e estado |
|---|---|
| Fontes/tipografia | Serifada licenciada, texto escuro nas duas placas, nomes e custo nativos. Título completo no destaque; repouso tem sobreposição entre cartas. Não foi identificada a fonte exata do original nem certificada acessibilidade. |
| Espaçamento/layout | Leque está no combate; um único botão destacado, com centro livre para alvos laterais. Quatro zonas do HUD e painel de plano são contexto de jogo adicional ao recorte do estudo. Repouso mais denso que o anexo. |
| Cores/tokens | Família madeira/folhas ou água/dourado preservada; natureza do poder continua escolhendo placas/linha interna. Não houve amostragem do PNG original. |
| Imagem/qualidade | Arte ampla sem faixa bege, custo sobre o retrato, miniatura circular, nenhum retrato redundante no rodapé. Molduras/pinturas continuam reconstruções candidatas, não equivalentes exatas aos desenhos aprovados. Sem novo desenho nesta fatia. |
| Texto/conteúdo | Dados reais de nome, UID, custo e alvo. `Cura em Lonlon (si próprio)` esclarece o destinatário; cena fixa não define alvo. `PRÉVIA`, estatísticas e pendências continuam explícitas. Título/setas/nota do estudo não foram copiados ao combate. |

## Pendências que bloqueiam aceite visual

- P1: falta fonte raster original acessível para comparação conjunta e revisão
  fiel dos contornos/ornamentos. Não há aceite artístico das molduras atuais.
- P1 de conteúdo conhecido, fora desta fatia: Semeadura/Chuva lateral sem
  pintura e catálogo parcial (6/73 candidatos; 67 imagens e duas molduras
  faltantes). Não promover esses assets a produção.
- A composição de repouso continua mais densa que a referência. A adaptação
  preserva controles de batalha e deve ser revisada por Pedro junto aos PNGs.

## Validação e próximo passo

Entradas reais verificaram seleção entre cartas sobrepostas, seis nós estáveis,
alvo inferior, inspeção, pilhas, toque e Conjurar uma única rodada. Nativos
posteriores passaram 49 checks de apresentação e 438 de entrada. O fechamento
integral atualizado é registrado em `artifacts/card-fan-final-acceptance/`; consultar o resultado
efetivo, sem inferir aceite de arte de sua contagem. Logs e capturas dos runs
focados permanecem nas respectivas pastas; as quatro capturas finais não
registraram falha de interação.

Abrir o PNG original no executor revisor, criar comparação conjunta nas mesmas
regiões/estados e ajustar/revisar as peças artísticas antes de declarar fidelidade
aprovada. Não foi feito merge, push, deploy ou upload de screenshots.
