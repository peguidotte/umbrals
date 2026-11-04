# V05-UX-05 — primeira casa de Pietro

Base: main `030ee7d` (PR #8), confirmada por preflight com fetch. Pedro definiu que
esta sala pertence à casa inicial e pediu abertura saindo da cama, cômodos
percorríveis em 2D e escada para o quarto da mãe. O abrigo dentro de um Umbral,
que a mãe dará depois, é outro lugar. Esta revisão não implementa a entrega.

## Percurso implementado

- Na primeira entrada de cada sessão, Pietro aparece sobre a cama e vai ao chão
  em 1,4 segundo. Uma direção ou ativação explícita da porta antecipa essa saída.
  Movimento reduzido começa ao lado da cama, sem rotação. O viajante atual é
  reutilizado; não existe uma animação de despertar dedicada.
- Caminhar à porta direita do quarto entra na sala. A passagem esquerda da sala
  retorna ao quarto. O livro abre o grimório real; a bancada conserva o aviso de
  melhorias indisponíveis.
- A passagem interna à direita da sala, ao lado da saída externa, leva à cozinha.
  E/Enter/A ou clique/toque aproxima antes de atravessar. A porta esquerda da
  cozinha retorna à sala; não existe menu de seleção de cômodos.
- A escada está na cozinha. Cima/baixo percorre sua diagonal, podendo parar e
  inverter o movimento; E/A ou ativação por ponteiro faz o percurso à velocidade
  de caminhada. O topo abre o quarto da mãe. A descida volta pela mesma escada.
- A porta externa da sala continua abrindo a preparação: Continuar, Nova com
  confirmação e Treino preservam os contratos existentes. Voltar restaura posição
  e foco, sem reabrir o painel automaticamente no limiar.

O nome do cômodo aparece por 2,5 segundos; não há barra permanente de instruções.
Os objetos atuais têm nome, tooltip e foco por Tab. Como jogar documenta controles.
Mouse/toque no chão define um destino físico; clicar na pintura fora do chão não
teleporta. Movimento direto, modal, troca de foco e perda de foco da aplicação
cancelam aproximações. Uma escada pausada pode ser retomada ou revertida.

## Estado e donos

`house_space.gd` possui geometria/adjacência. `house_motion.gd` possui somente
apresentação transitória de cama/escada. `refuge_room.gd` coordena esse espaço e
emite as intenções já existentes; `refuge_canvas.gd` desenha cenários/ator separados.
Os IDs `refuge.*` e o root antigo são aliases de compatibilidade de UI; o snapshot
público identifica `location: pietro_house` e o cômodo atual. Eles não definem que
a casa seja um abrigo portátil.

Nenhuma alteração em main, aplicação, Rules, sessão, catálogo, RNG ou schema de
save. Posição da casa é transitória e conservada ao voltar ao título nesta sessão;
reload reabre no quarto. Continuar só restaura a expedição ao confirmar a opção
existente. Não se grava um segundo checkpoint da run ao caminhar na casa.

A implementação do abrigo futuro deve ter identidade, geometria, arte e entrada
próprias; não pode reutilizar esta casa nem transformar o quarto da mãe num botão
que dá o Umbral. A cena de conversa/entrega e a continuidade narrativa da abertura
são a próxima fatia. Não há NPC, diálogo, cura, inventário doméstico, afinidade ou
economia inventados nesta revisão.

## Arte e proporção

A sala conserva a composição do PR #8 e recebe passagens pintadas em
`world/refuge-lateral@1.1.0`; a release 1.0.0 é imutável. Os outros cômodos usam
`world/pietro-house@1.0.0`, atlas original com regiões explícitas. Os PNGs originais
e metadados permanecem intactos; geração/referências/hashes constam dos manifests.
O sprite separado não muda de identidade, escala relativa ou pixels entre salas;
um tom levemente quente e sombras de contato em duas camadas o apoiam no piso.

Revisão das capturas reais: a primeira sobreposição de portas parecia um bloco
sobre a pintura e foi removida. A versão pintada mantém a mesa, sofá e saída,
com vistas para interiores nos acessos. Os novos quartos e cozinha mantêm madeira,
luz âmbar e janelas azul-esverdeadas. O atlas tem menos resolução por sala que o
cenário original; acabamento final e aprovação de Pedro continuam separados de
validação funcional. O corpo de Pietro sobe na frente da escada, sem uma camada
de corrimão que o oculte; animação/oclusão dedicada é refinamento posterior.

## Evidência e integração

`house-input`: 44 checks nativos e arquitetura passaram. `house-painted-visual`:
71 checks Web, vídeo e capturas dos quatro cômodos, subida/descida, grimório,
ponteiro/toque e fluxo exato de Continuar passaram. Primeiro teste com expectativas
antigas foi preservado com falha; a tentativa intermediária `house-painted-passages`
foi invalidada pelo próprio harness ao detectar edição de fonte durante o teste,
ainda que suas 44 asserções tenham passado. Nenhum gate foi reduzido.

O fechamento repete os testes com fontes congeladas e acrescenta captura e
geometria de todos os cômodos nos cinco formatos contratados. O PR registra o
resultado final, hashes e CI reais. Evidência focada não é aceite integral.
Teclado/controle no Godot são eventos injetados; mouse, teclado e toque Web usam
entrada real do navegador. Não se declara teste de controle físico, áudio,
performance em hardware, animação final ou aprovação subjetiva de Pedro.

Riscos de integração: catálogo/proveniência/bindings de assets e runtime-lock são
gerados e podem conflitar com a frente de ferramentas; regenerar a união dos
módulos/pins sem sobrescrever releases. A única mudança no cenário de layout do
harness chama o helper da casa. Não há edição do registry, baseline, main, combate
ou fluxo de run. A branch fica em PR de rascunho para integração coordenada;
nenhum merge automático ou manual é realizado aqui.
