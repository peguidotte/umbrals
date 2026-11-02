# Direção visual da primeira batalha coletiva

Referência de composição: [formato aprovado](references/battle/00-aprovada/README.md).
Esta implementação mantém PC como alvo e troca a arena de um único adversário
por até três atores de cada lado, com dados nativos e alvos interativos.

- **Câmera:** confronto horizontal levemente elevado. Grupos quase alinhados,
  com curvatura suave; o centro fica disponível para trajetórias de ataques.
  Posição superior/central/inferior tem identidade estável, sem retaguarda.
- **Chão e escala:** cenário menor e chão contínuo sob os seis apoios. Sprites
  têm sombra/apoio; ociosidade não faz os pés flutuarem. Não preencher vagas
  vazias com criaturas de mentira para equilibrar a imagem.
- **Revisão de profundidade (V04-ART-06A):** arena panorâmica mais limpa,
  enquadrada somente na área acima do HUD, com horizonte no alto e textura de
  chão discreta. Atlas usam filtragem nearest; os pés visíveis têm âncoras e
  largura de contato próprias nos JSONs. Sombras têm contato estreito e borda
  suave. A escala visual superior/central/inferior é 90%/100%/107%, com leve
  tonalidade fria no alto; HP, hit areas e posições lógicas não mudam. Isso
  sugere distância, sem criar frente/retaguarda nem modificadores de combate.
- **Família de arte:** atlas original em pixel art, separado da arena sem HUD.
  PNGs gerados permanecem intactos. O motor usa regiões do atlas e fallback
  vetorial original quando necessário. Ataques e dados continuam independentes.
- **HUD:** reservas em grade 3×2 à esquerda; cartas no centro; ações/Conjurar/
  Resortear ao lado; mochila, compra e descarte na direita. A mão base é seis;
  modificadores precisam caber sem esconder o dono ou o botão de confirmação.
- **Atores:** HP, nome, condições e intenção próximos ao dono. Inspeção apresenta
  atributos; inimigos mantêm seus nomes próprios. Área da técnica destaca as
  posições atingidas, sem confundir espaço entre sprites com alcance.
- **Feedback:** trajetórias no corredor central, impacto e números por alvo,
  seguindo a ordem real da resolução. Partículas, vozes e textos temporários
  têm limites; movimento reduzido limpa efeitos em andamento.
- **Informação:** intenção parcial por padrão. Ocultar um golpe também exige
  ocultar detalhes na fila, no alvo destacado, na inspeção e na prévia.

A composição aprovada orienta a entrega, mas qualidade visual será descrita a
partir das capturas reais. Animações de poses completas, materiais finais e
aprovação de todas as espécies continuam trabalho posterior.


## V04-UX-05A — base visual implementada, em avaliação

Tokens compartilhados no `kit.gd`: tinta `#0c1026`, superfície `#141b36`,
elevação `#242c4c`, borda `#59658f`, cristal `#b5a0fa`, texto `#eeeaf7`,
secundário `#aab6d5` e âmbar `#f2bd70`. Naturezas mantêm o catálogo.
Custos usam cristais; ações livres/planejadas combinam marcas e contagem;
seleção e edição de alvo têm sinais distintos. Molduras ficam retas e discretas.

Cartas exibem retrato/UID do dono, arte ampliada e títulos por palavras em
fonte fixa, com detalhes no plano/inspeção. Mãos ampliadas têm rolagem com foco.
O mapa reaproveita a floresta original com trilhas conectadas, cristais e marcos
do catálogo. Não foram geradas novas pinturas de poderes ou marcos nesta fatia.
Câmera, âncoras dos atores, corredor central, formação e regras não mudaram.

A paleta foi adotada por delegação para avaliação, sem nova aprovação estética
atribuída ao usuário. PC e toque emulado foram capturados; o texto em 844×390
continua pequeno. O HUD compacto e a arte dedicada são a próxima recomendação
antes do mercador. [Resultados e limites](ux-reference-v04-05a.md).

## V04-UX-05B — abertura escolhida pelo usuário

A referência passa a ser `ui/title-menu@1.0.0`: somente a palavra UMBRAL,
marfim/branco e lilás sobre índigo, formas angulares limpas e ícones menores
sombreados. O usuário indicou essa logo como referência para a cor e o feeling
das próximas telas, substituindo a aparência medieval dos botões. Bosque e
cartas foram preservados conforme a terceira revisão selecionada.

A abertura usa os pixels originais e controles Godot reais sobre suas regiões;
efeitos de luz/energia pertencem à apresentação, com movimento reduzido. A
propagação dessa identidade ao restante do jogo depende das próximas fatias.
O HUD e a composição de batalha aprovados não foram alterados aqui.
[Implementação e verificação](title-menu-v04-05b.md).

### V04-UX-05C — menu em camadas

As seis melhorias foram aprovadas juntas pelo usuário. Conservar a composição,
os quatro comandos, a arte das cartas e a logo limpa. Separar o bosque em uma
camada própria permite flutuação/rotação real, sem deformar o cenário inteiro.
O novo fundo `world/title-forest@1.0.0` deriva da referência; a logo transparente
`ui/title-logo@1.0.0` retoma a versão limpa já aprovada. O PNG de 05B continua
intacto e fornece as cartas/botões por regiões e polígonos no renderer.

Foco acompanha o chanfro; hover e pressão são discretos. Jogar usa superfícies
índigo/violeta e texto marfim, retratos do catálogo e o ponto real do save. O
mesmo bosque preenche formatos variados; na vertical, as cartas ficam acima
dos comandos. Movimento reduzido fixa poses, remove partículas/pulso e evita
transições. Sons de cristal e água são síntese original nos buses existentes.
Esta é a linguagem do menu; a batalha não recebe uma reformulação nesta fatia.

## V04-UX-05D — direção dourada selecionada

O usuário comparou explicitamente o menu atual violeta com a dupla proposta e
escolheu menu centralizado e grimório dourado. A abertura passa a usar floresta
azul-esverdeada, pergaminho e ouro antigo, com sprites de batalha originais;
Brasa → Ignivar e Musgo → Verdálio preservam suas identidades. Texto, foco e
controles são nativos. O grimório revela conteúdo por descoberta persistente.
Essa seleção substitui a direção da abertura 05B/05C; o HUD de batalha conserva
seus contratos. [Entrega e validação focada](gold-menu-codex-v04-05d.md).

V04-UX-05H estende essa direção às Opções, tanto no título quanto na pausa:
floresta e moldura botânica existentes, Cormorant, papel/verde profundo/ouro,
sliders e switches nativos. Áudio, acessibilidade e informação são agrupados;
o rodapé fica fora da rolagem. [Capturas e limites](settings-gold-v04-05h.md).

Em V04-UX-05I, o usuário fixou o nome **Umbral**, sem subtítulo. A abertura
exibe apenas esse nome; a linha de marca das Opções foi removida e Voltar ganhou
respiro em relação à moldura inferior. Como jogar fica adiado até a revisão das
mecânicas, incluindo a decisão de manter ou substituir essa tela.
