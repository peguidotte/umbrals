# Revisão visual da primeira batalha coletiva

Revisão local do jogo exportado para Web, com entrada real de mouse/teclado. A
referência é o [formato aprovado](references/battle/00-aprovada/README.md), não
uma meta de igualdade de pixels. Esta revisão não substitui as cinco primeiras
sessões humanas do marco.

## Composição e leitura

- Os três apoios de cada lado preservam superior/central/inferior em grupos
  quase alinhados, com leve avanço do membro central. A mesma arena/escala
  funciona no início solo, em 2×3 e no 3×3 real, sem preencher vagas vazias.
- HP e nome ficam abaixo do próprio corpo; intenção fica acima do adversário.
  A revisão inicial encontrou colisão entre nome/HP e entre intenção e condição
  do ator vizinho; a integração compactou os rótulos e aumentou o espaçamento.
- O corredor central continua livre. Brasa, Orvalho e Faísca têm silhuetas e
  cores reconhecíveis em trio. Ignivar usa a forma evoluída em cena. Isso não
  valida seis corpos grandes/evoluídos simultâneos nem todas as poses.
- O HUD mantém a sequência escolhida: grade de reservas 3×2, mão, ações e
  confirmação/passe, mochila e pilhas na extremidade direita. Se todos os três
  integrantes estão ativos, a grade mostra células vazias; não inventa reservas.
- As cartas indicam custo, dono e alcance. Contorno e marca de seleção diferem
  do foco claro; o erro também explica o orçamento, além da mudança de cor.
  A prévia é potência condicional dos poderes, não previsão exata de HP inimigo.

## Fluxo, feedback e opções

- Mochila abre um modal com alvo, HP e custo; consultar não gasta ações. O fluxo
  real planeja e confirma poção. Reanimação/reposição têm cobertura numérica; a cena verifica rótulos e foco
  das cartas bloqueadas. A rota do navegador não exercita reanimar/substituir após nocaute.
- A entrada de reserva explica ação, confirmação no Conjurar, golpe recebido
  pela vaga e cartas na próxima compra. Captura e evolução têm artes/indivíduos
  próprios; não há cura automática implícita ou assinatura adicionada ao deck.
- A sequência de vídeo mostra trajetórias, impactos e números por alvo, com
  retorno ao repouso. A revisão identificou uma atualização antecipada da mão
  durante a animação; a correção mantém as cartas conjuradas/selecionadas até
  terminar a fila e distingue incapacitação de espera após reanimação.
- Movimento reduzido elimina tremor/partículas e mantém os controles; flashes
  começam desativados. Opções mostram claramente que o nível de informação
  vale na rodada seguinte. O plano inimigo não muda ao alternar a projeção.

## Formatos e limites

Menu, batalha inicial solo, pausa/opções e texto ampliado são exercitados em 1280×720,
1440×900, 1920×1080, 1024×768 e 2560×1080. Os controles permanecem dentro do
canvas. O 3×3 real é capturado em 1600×900; a matriz não cobre todas as
formações em cada formato. O ultrawide recorta parte do horizonte para
manter o chão cobrindo a arena. Em 1024×768, o ajuste do canvas de referência reduz o tamanho aparente
das cartas; cabe, mas leitura confortável ainda precisa de avaliação humana.

A tipografia/painéis ainda têm aparência de protótipo; as cartas usam ícones
vetoriais e nome do dono, sem retrato individual. As criaturas usam poses
estáticas com ociosidade/efeitos procedurais. Ataques em área, poses e identidade
visual completa continuam no polimento da família. Não há avaliação em celular,
controle físico, áudio em hardware ou medição de performance mínima.

## Próximo experimento

Manter a câmera elevada e a formação quase linear nesta base. Observar cinco
primeiras sessões antes de ampliar mapa/lojas: localizar dono/alvo/HP, entender
velocidade e passe, perceber água antes de raio, comparar concentração num dono,
cooperação e proteção. As simulações verificam conservação e término; não
comprovam equilíbrio nem que essas escolhas são interessantes.

## Evidência

Rodada aprovada: `artifacts/battle-v04-final-20261018T231232307414Z`. O `run.json` preserva os resultados automáticos e o
hash das fontes; `review-notes.json` registra as observações posteriores sem
reescrever o resultado. Capturas de referência da revisão:

- `05-battle.png`: início solo e vagas preservadas.
- `08a-backpack.png`: consulta e planejamento de consumível.
- `10-cast-feedback.png`: mão mantida durante a fila e impacto por alvo.
- `11-capture.png`, `11-evolution.png`, `14-reserve-planning*.png`:
  recompensa e entrada com custo/confirmação.
- `12-evolved-boss.png`: Ignivar em combate 2×3.
- `15-actual-three-vs-three.png`: três aliados e três inimigos vivos.
- `matrix-*.png`: cinco formatos com opções/texto ampliado.

Os PNGs ficam em `browser/` dessa rodada; o vídeo original é `browser/gameplay.webm`.
O trecho de impacto foi revisto em quadros, além dos snapshots/gates de retorno
ao repouso. São 39 capturas e 754 verificações de navegador, sem falhas.
Os originais das tentativas anteriores permanecem preservados, inclusive as falhas.

## Revisão posterior de chão e profundidade

O feedback sobre ruído do fundo e apoio do Orvalho levou à [V04-ART-06A](visual-review-depth-v0.4.md): panorama mais limpo, enquadramento do campo, âncoras de pés e sombras por arte. A nova revisão preserva esta evidência histórica e registra seus próprios renders/testes.
