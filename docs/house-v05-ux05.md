# V05-UX-05 — casa contínua de Pietro

Base atual: main `1523d0e7a34ef605bab140f9a979bc06a917f185`, incorporada na
branch após fetch explícito de main. A Nascente contextual, ruleset 3 e migrações
da run trazidas pela main foram preservadas sem alteração. A versão anterior usava vistas
separadas; Pedro rejeitou essa solução após ver o vídeo. Ela está superada.
Esta revisão mantém quarto, sala, cozinha e quarto da mãe em um único mundo 2D.
O abrigo portátil dentro de um Umbral, que a mãe dará depois, é outro local futuro.

## Comportamento

A primeira entrada começa sobre a cama: uma apresentação de 1,4 segundo gira a
pose de repouso até ficar em pé. Direção/E antecipa a saída; movimento reduzido
começa no chão. Não existe animação dedicada de despertar.

Quarto de Pietro à esquerda, sala ao centro e cozinha à direita compartilham o
mesmo piso. Caminhar muda apenas a região semântica, sem trocar textura, cena,
posição ou escala. A câmera acompanha nos dois eixos, com limites do mundo e
projeção inversa compartilhada com os cliques no chão. O andar superior fica à
esquerda do vão da escada; após subir, caminhar à esquerda alcança o quarto da mãe.
A borda do piso superior bloqueia a caminhada para o vão.

A escada possui degraus, apoio e corrimão distante antes do ator; postes, viga e
corrimão próximo depois do ator durante a subida/descida. No térreo, a faixa de
caminhada passa à frente da escada inteira, evitando que a viga corte o corpo
de quem apenas atravessa a cozinha. Os pés seguem patamares com uma curta elevação
entre eles. E/clique aproxima até a extremidade exata e faz o percurso físico;
cima/baixo permite controlar e inverter o movimento. Entrada lateral aproxima
antes de subir, sem reposicionar o ator por salto. Pausar conserva a última
direção: E/clique retoma a subida ou descida, inclusive acima/abaixo da metade.

Livro abre o grimório real, bancada avisa melhorias indisponíveis. A porta externa
da cozinha abre a preparação existente, sem iniciar uma run automaticamente.
Voltar conserva posição e foco sem reabrir a porta. Mouse/toque caminha pelo chão;
movimento direto, Tab, modal e perda de foco cancelam aproximações. Objetos têm
nomes e foco por Tab apenas quando uma área utilizável está visível na câmera.
Não há seletor de cômodos nem barra permanente de instruções.

## Donos e continuidade

`house_space.gd`: coordenadas, pisos e regiões. `house_motion.gd`: cama/escada e
andar transitório. `house_camera.gd`: enquadramento/projeção. `house_stairs.gd`:
camadas de profundidade. `refuge_canvas.gd`: um cenário e ator separados.
`refuge_room.gd`: entrada, foco e intenções já existentes. Os IDs `refuge.*`
continuam aliases de compatibilidade; o snapshot identifica `pietro_house`.

Rules, main, aplicação, RNG, conteúdo mecânico e schema de save permanecem nos
donos existentes. Caminhar não grava um segundo checkpoint. Posição da casa é
conservada na sessão; reload recomeça no quarto. Continuar restaura a expedição
pela opção existente. Nenhum NPC, diálogo de entrega, cura, economia ou abrigo
portátil foi inventado para completar esta fatia.

## Arte e limites

`world/pietro-house-continuous@1.0.0`: um PNG original, sem atores ou escada
embutida. `characters/pietro-home@1.0.0`: atlas separado, pele mais clara,
cabelo escuro encaracolado, roupa inicial azul/dourada e proporção menos caricata.
Cenário e ator usam contornos e paleta próximos; a escala foi calibrada sobre
mobília e porta nas capturas reais. Todos os PNGs/metadados originais ficam
intactos, com pivôs e escala em JSON, hashes e pins explícitos. Releases anteriores
continuam imutáveis; os novos bindings selecionam a revisão contínua.

A Library confirmou a referência aprovada `libfile_7a1f2d2e78ac8191a4109773df9dce86`
mas sua transferência oficial falhou (`download failed`). O ator é uma
interpretação provisória, não uma reprodução fiel da imagem que não foi aberta.
O corrimão é geometria nativa com acabamento inicial; caminhada usa sete poses,
sem animação específica de subir escada. Aprovação estética permanece com Pedro.

## Validação e integração

As tentativas anteriores de cenas separadas e seus vídeos não aprovam esta versão.
Os testes desta revisão verificam continuidade de coordenadas/câmera, projeção de
ponteiro, limites dos dois pisos, margem do atlas na escada em cinco resoluções,
pausa/retomada/inversão, foco/modal, teclado/controle injetados no Godot, mouse e
toque real em Chromium e preservação do checkpoint/RNG. Os relatórios novos
identificam o HEAD e a base exatos. Evidência focada não é aceitação integral.

Capturas e vídeo reais são revisados; MP4 é transcodificação do vídeo de navegador,
sem quadros fabricados. Não se declara controle físico, celular físico, áudio ou
performance em hardware. Os resultados finais e caminhos estão no relatório de
entrega; falhas intermediárias são preservadas em `artifacts/harness/`.

Arquivos gerados de assets/runtime-lock podem conflitar com a frente de autoria;
regenerar a união de módulos/pins, sem sobrescrever releases. Não foram alterados
registry, baseline, main, batalha ou fluxo da run. PR #11 permanece rascunho,
sem merge até revisão coordenada. A atualização de descrição anteriormente negada
não foi repetida nem publicada por outra via.
