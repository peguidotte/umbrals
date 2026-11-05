# V05-ART-02 — poses de despertar e escada, em avaliação

Esta fatia está em branch separada, sobre `1fda638` do PR #17. A revisão anterior
permanece congelada e terminou com os sete jobs de CI aprovados na execução
`41960266212`, incluindo a aceitação completa agregada. O resultado pertence
àquela revisão; não certifica as mudanças desta fatia.

## Resultado visível e estado de aprovação

O despertar usa seis desenhos completos: deitado, apoiado no cotovelo, sentado
com joelhos recolhidos, sentado na borda, levantando e em pé. Não há rotação da
pose em pé. A sequência dura 2,4 segundos; direção/E antecipa o final e movimento
reduzido começa diretamente no chão. As duas poses finais têm a sola calibrada
nos pixels reais para `FLOOR_Y`, preservando a chegada exata no chão.

Subida e descida usam dois atlas próprios de oito poses, em vez de caminhada
lateral. A seleção acompanha o progresso nos degraus, não o relógio da caminhada.
Pausar mantém o mesmo desenho; inverter o percurso troca a família; movimento
reduzido mantém uma pose própria sem bloquear a travessia. O corrimão continua
em frente ao corpo e a geometria da casa permanece intacta.

**Não considerar a animação de escada pronta para aceite estético.** Os desenhos
mostram flexão e alturas de pés distintas, mas a perna dianteira ainda domina a
subida e a alternância parece um passo juntado. Faltam alternância mais clara,
continuidade fina dos apoios e entrequadros para uma cadência natural. Uma nova
tentativa não resolveu esse problema e não foi selecionada. O despertar melhorou
a leitura na cama, mas seus seis desenhos ainda produzem mudanças perceptíveis
de orientação; a saída sentado → apoiado no chão deve receber revisão humana.

## Donos e contrato

- `pietro_pose_view.gd`: seleção cosmética, pivôs e âncoras dos desenhos.
- `refuge_canvas.gd`: desenho da textura selecionada, bounds e estado cosmético.
- `house_motion.gd`: avanço do despertar e publicação do progresso já existente.
- `refuge_room.gd`: preferências e aviso de mudança de pose para o snapshot de
  leitura; não oferece setters ao navegador.
- `characters/pietro-home-transitions@1.0.0`: três PNGs originais, regiões e pivôs,
  prompts e tentativas de referência preservadas em `review/`.

O personagem base `characters/pietro-home@2.0.0` permanece imutável. O novo módulo
depende explicitamente dele; um binding adicional seleciona o módulo de transição.
Não há alteração em main, Rules, sessões, conteúdo mecânico, checkpoint, RNG,
geometria, câmera ou velocidade de travessia da escada. A posição da casa continua
transitória. Índices de assets devem ser regenerados preservando a união de pins
das demais frentes; registro do harness e baseline não foram alterados.

## Pixels, testes e evidência

Os PNGs de saída permanecem byte a byte. O atlas de despertar tem distribuição
irregular; seis figuras completas e não sobrepostas usam regiões explícitas.
Há RGB colorido sob alfa zero, que não é um fundo opaco; o render real foi
conferido. `review/check_source.py` verifica hashes, alfa, regiões, margens e as
solas finais contra o chão. O último desenho de descida tem margem opaca mínima
de um pixel no PNG; isso continua sendo uma limitação de margem de filtragem.

A primeira execução nativa ainda esperava a rotação e o tempo anterior do
despertar. Foi preservada como falha; as expectativas foram sincronizadas e a
execução seguinte passou 99 verificações. A revisão dos dois pivôs finais recebe
duas verificações adicionais e um novo fechamento focado, registrado no handoff.
Não foi repetida a suíte completa de combate por esta fatia cosmética.

`tools/capture_pietro_transitions.py` usa teclado, cliques e controles reais em um
build Web, com observação somente de leitura. O primeiro percurso passou 17
verificações e registrou as seis poses em ordem, subida, descida, pausa, inversão,
movimento reduzido e preservação dos campos de expedição/checkpoint. A gravação
final deve identificar sua revisão e os pivôs efetivamente capturados; MP4 é
transcodificação de vídeo real, sem quadros fabricados ou áudio acrescentado.

Os resultados são focados e não constituem aprovação visual, prova de diversão,
desempenho em hardware ou teste com controle físico. A branch deve permanecer
draft, sem merge, até revisão independente; a cadência da escada continua aberta.
