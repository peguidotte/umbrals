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
