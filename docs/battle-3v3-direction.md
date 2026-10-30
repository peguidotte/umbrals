# Batalha até 3×3 — formação escolhida

Estado: **formação escolhida e integrada na primeira fatia coletiva, validada localmente**. Ver [implementação](battle-implementation-v0.4.md). O teto é
**três ativos por lado, com até seis no time**. Preencher as três vagas é opcional:
um ativo com cinco reservas contra três inimigos é uma formação legal. O
[alvo visual do MVP foi aprovado](references/battle/00-aprovada/README.md):
horizontal elevada, grupos quase alinhados e HUD em quatro zonas. Triângulos e
diagonal são histórico de exploração. O executável continua 0.3.0.

D38–D40 acrescentam iniciativa por velocidade individual e três posições em
linha por lado: superior, central e inferior, sem retaguarda. Golpes podem atingir
uma posição, superior + central, central + inferior ou todas. O substituto recebe
ataques destinados à vaga que assume.

## Formação e orçamento

- A run continua começando com um Umbral. O jogador escolhe de um a três ativos,
  independentemente da quantidade inimiga. Com seis integrantes, são legais
  **1 ativo + 5 reservas**, **2 + 4** e **3 + 3**. Não preencher vagas automaticamente.
  Um time com só um integrante também continua permitido.
- Até seis integrantes no time. Seis vagas disponíveis desde o início é uma
  proposta coerente com a nova direção; não exige preencher todas nem aumenta
  ações, HP individual ou compra automaticamente.
- O teto de três ativos vale também para os adversários. Relíquia, item ou
  espécie não abre quarto slot em campo. Reservas adversárias não são presumidas.
- **Três ações do grupo** é a nova hipótese inicial, sugerida pelo usuário; não é
  uma ação por criatura. Continua permitido concentrar o orçamento num indivíduo.
- Relíquias que ampliam ações são possibilidade de design, sem quantidade final,
  empilhamento ou efeito aprovado. D36 confirma mão base seis, podendo aumentar
  ou diminuir por itens e Umbrals; isso não aumenta ações ou o teto ativo.

Esta direção preserva três papéis simultâneos: preparador, finalizador e protetor.
Não exige um integrante de cada papel nem uma ação de cada dono em toda rodada.
Com seis corpos na arena, permite mais espaço que o 4×4 e mantém uma combinação
com três espécies na mesma conjuração. A legibilidade ainda exige revisão em cena.

Os seis corpos são o caso máximo. O tamanho inimigo não define a formação aliada;
não criar um modo separado de run só para permitir 1×3. A reserva não é um ativo
invisível: participação, auras e cartas dependem das regras ainda em design.
Quantidade ativa não altera automaticamente o orçamento do grupo. Uma ocupação
menor pode adaptar os pontos de apoio e preservar presença, sem silhuetas de
ausentes. Com D39, os identificadores superior/central/inferior precisam continuar
claros; não renumerar posições ou mudar alcance ao reduzir a ocupação.

Troca voluntária custa uma ação e só executa ao confirmar Conjurar (D33), como
os poderes planejados. A fase exata e entradas/retiradas sem substituição ainda
precisam de detalhamento; prioridade da troca antes dos golpes comuns é proposta.
Reposição após nocaute é gratuita entre rodadas, depois da fila completa dos dois
lados (D37/D38). Se todos os ativos caírem e houver reserva apta, escolher ao
menos um substituto para continuar, sem obrigar a preencher três. Não confundir
manter um único ativo com derrota enquanto os outros estão na reserva.
Reanimar permite agir na rodada seguinte, se apto e em campo.

## Exemplo de decisão

Com três ações e técnicas simples custando uma cada: Orvalho tenta aplicar
Encharcado, Faísca usa Descarga e Musgo protege um aliado. A velocidade individual
define a ordem de atuação (D38), junto das exceções explícitas propostas para
técnicas. Orvalho precisa agir antes de Faísca ou aproveitar uma marca já
existente para obter o combo; clicar água primeiro não o garante. Um inimigo
pode agir entre os dois e interromper o plano. A troca custa uma ação, deixando
duas para os integrantes que seguem em campo. Cartas de quem entra somente na
próxima compra normal é recomendação aceita, sem compra imediata na seleção da troca.

Golpes de custo dois obrigam a dispensar parte dessa sequência. Cura, proteção,
troca e ataque devem oferecer usos situacionais; não criar sempre a mesma tríade
obrigatória. O [estudo de combos](formation-and-combos-study.md#ordem-predefinida-para-combinar-poderes)
detalha a proposta de iniciativa e combos. Custos e balanceamento precisam de protótipo.

## Relíquias de ações

Recomendação de primeiro teste: comparar um quarto ponto permanente com uma
ação adicional condicional, sem tratá-los como equivalentes. Passar de três para
quatro aumenta o orçamento em um terço e abre ataque ou proteção adicional.
É uma mudança de decisões, não apenas um número pequeno.

Exemplo candidato: conseguir uma ação extra na rodada seguinte a uma combinação
de três donos, uma vez por encontro. Outro candidato pode favorecer trocas, com
limite explícito. Nenhum desses efeitos está aprovado. Uma relíquia de ação não
deve ser necessária para a run básica funcionar; observar se acaba substituindo
todas as outras recompensas. Não limitar a produção antecipadamente a esses itens.

## Reservas fora da compra — confirmado em D32

Cartas dos reservas aptos não entram no embaralhamento, compra ou mão ativos.
Com o repertório inicial aceito de três poderes com duas cópias por dono e três
ativos aptos, são 18 cartas elegíveis; as outras 18 do time cheio ficam separadas.
A mão base é seis, modificável por itens e Umbrals (D36).

Preservar instâncias/estado das pilhas ao trocar exige detalhamento, sem compras
ou reinício gratuito do ciclo. Cartas de incapacitados continuam bloqueadas nas
zonas ativas conforme D19; dono incapacitado não é reserva apto, e repor a vaga
não autoriza remover essa penalidade. Ver [proposta atual](battle-design-v0.4.md).
As mãos das imagens continuam ilustrativas; a política foi confirmada em texto.

## Conceitos para PC — histórico de exploração

1. **Triângulos abertos — seleção anterior, sucedida por D31.** Até três aliados à esquerda e três
   inimigos à direita, em grupos triangulares espaçados. Preserva a leitura da
   composição selecionada e abre um corredor para golpes. Conferir interseção
   de efeitos com sprites dianteiros e espaço para corpos largos.
2. **Frentes da clareira — histórico, fora da exploração atual.** Três inimigos acima e três aliados abaixo, usando toda
   a largura. Distribui corpos e HP com clareza; pede sprites coerentes com a
   câmera elevada e reconhecimento das criaturas vistas em três quartos.
3. **Diagonal panorâmica — seleção anterior, sucedida por D31.** Aliados embaixo à esquerda, inimigos em cima à direita.
   Oferece um corredor longo e profundidade; rótulos superiores e percepção de
   distância precisam de mais cuidado. Posição visual não define alcance.

Todos mantêm itens numa mochila única, indicador pequeno de rodada, ações perto
de Conjurar, HP por ativo, intenção parcial por categoria, cartas com dono e três
retratos pequenos de reserva. Mesmas criaturas, estilo 2D simples e feitiço de
água permitem comparar composição sem trocar a identidade do jogo.

Na diagonal, **reprojetar os sprites para o eixo do confronto**: aliados em três
quartos de costas, olhando para cima/direita; adversários em três quartos de
frente, olhando para baixo/esquerda. Cabeça, tronco, patas, asas e origem do golpe
precisam concordar. Espelhar o sprite ou mudar só os olhos não resolve. Manter
assinatura de silhueta, escala, paleta e chão; retratos das cartas podem ser frontais.

O refinamento atual varia três situações em ambos os conceitos: bosque com
descarga elétrica, santuário com trio diferente/vento/proteção e cenário frio
com um ativo, cinco reservas e golpe de brasas. Novos nomes, formas e poderes
são estudos autorais, sem aprovar conteúdo ou ampliar o escopo do catálogo.

As três imagens, prompts, cópias e manifesto estão em
`artifacts/battle-3v3-20261016T040247Z/`. O usuário escolheu aprofundar 1 e 3;
as imagens específicas dos refinamentos ainda dependem de revisão.

### Variações dos dois conceitos escolhidos

Nova série em `artifacts/battle-selected-variations-20261016T041729Z/`:

| Situação | Triângulos abertos | Diagonal panorâmica |
|---|---|---|
| **Bosque úmido · 3×3** | Musgo/Orvalho/Faísca, descarga em alvo Encharcado, três reservas. | Mesmo elenco e golpe, corpos aliados em três quartos de costas no eixo do confronto. |
| **Santuário ao entardecer · 3×3** | Brasa/Peregrumo/Velária, vento com folhas e abrigo, três adversários novos propostos. | Elenco e cenário correspondentes; poses reprojetadas para o confronto em diagonal. |
| **Pântano frio · 1×3** | Só Brasa em campo, cinco reservas e espiral de brasas contra três adversários. | Mesmo caso assimétrico, com Brasa voltado para cima/direita e inimigos para baixo/esquerda. |

Na equipe de um ativo, a prancha mostra seis cartas daquele dono, sem preencher
a mão com cópias inventadas. Isso não aprova filtrar reservas da compra: mãos,
contadores e custos são ilustração. Novos adversários (Cascário, Campânulo,
Lodouro e Nivalume) têm [briefs de identidade](creature-identity.md#novos-estudos-para-as-variações-de-cenário),
sem virar automaticamente catálogo implementado. Preservar também rascunhos e
correções de UI no manifesto; não tratar a imagem gerada como HUD funcional.

## Evidência necessária

### Referência anterior: diagonal no pântano frio

O usuário destacou a imagem `diagonal-solo.png` da série selecionada como base
para variações **1×1, 2×2 e 3×3**, pedindo maior consistência de espaçamento e
disposição. O [brief de layout diagonal](battle-layout-diagonal.md) fixa a
mesma câmera/cenário, escala por espécie, centros dos grupos e passo regular
entre apoios. A formação completa fundamenta as versões menores; não redesenhar
um campo diferente para cada contagem.

As mãos/HUD ficam iguais para isolar a comparação visual. Reservas acompanham
os ativos reais: cinco, quatro ou três retratos. Isso não altera a liberdade de
1×3 ou outra ocupação assimétrica, nem decide compra/custo de troca. Nova série:
`artifacts/battle-diagonal-consistent-20261016T043102Z/`.

A extensão D27 pede **3×3 de evoluídos grandes**, na diagonal e na horizontal
(grupos esquerda/direita, ambos em tela PC). Comparar as mesmas famílias,
preservando arena/câmera/HUD e aumentando a presença dos corpos. São propostas
de evolução, sem ampliar catálogo ou regras. O [estudo de escala](battle-layout-diagonal.md#estudo-de-escala-dos-evoluídos)
descreve o teste; evidência em `artifacts/battle-evolved-3v3-20261016T044037Z/`.

As imagens são conceitos estáticos. Conferir corpos/HP conforme os ativos reais,
até três intenções inimigas, retratos conforme as reservas e orçamento compartilhado
de três como hipótese. Incluir 1×3 com cinco reservas, sem auto-preenchimento, além
do máximo 3×3. Em engine, testar início solo, dupla/trio, substituição, golpe em área, efeito de relíquia, mão bloqueada,
movimento reduzido e foco da mochila. Não declarar animação, equilíbrio ou diversão
validados pela geração. A versão do jogo só avança após os critérios do marco.
