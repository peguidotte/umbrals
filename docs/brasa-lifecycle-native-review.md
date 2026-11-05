# Brasa — revisão nativa de poses, V05-ART-01C

O blocking de malha 0.1.0 permanece reprovado e preservado. Esta revisão avalia
poses novas da mesma forma `ember`, sem explorar ou produzir o final de fogo.
Sendral continua aprovado; o final principal aguarda a nova proposta quadrúpede
com três caudas e juba menor. Nenhuma dessas decisões aprova automaticamente
os pixels novos de Brasa.

A fonte `exec-90926448-5f64-4ca6-8e15-070e807370c9.png` foi criada por Image Gen
com o Brasa existente como referência. Há oito poses bípedes de locomoção e
quatro de incapacitação reversível. O original RGBA é preservado integralmente.
As células recebem apenas cortes e translações inteiras para alinhar o chão;
sem pintar, redimensionar ou remover metadados da fonte. A referência usada
no pedido foi a região original de Brasa ampliada para inspeção, não um design
novo da família.

O preview `artifacts/brasa-lifecycle-candidate-imported/` usa Godot 4.6.3 e Mesa
llvmpipe, 1600×900, com vistas a **118 px** (altura real da batalha), espelhada
e ampliada 3×. Foram capturados 60 frames a 30 FPS. A primeira tentativa sem
importação foi preservada, interrompida e não usada como evidência visual.
A importação estável passou antes da captura válida.

Nos frames de caminhada, um pé fica no apoio e o outro aparece levantado e
cruza para o passo seguinte. O corpo avança, em vez de apenas balançar sobre
um mesmo desenho. Cauda, face e cores continuam reconhecíveis no tamanho real.
O ciclo tem variações no espaçamento dos passos e na altura da cauda; revisão
independente de fluidez e aderência dos pés permanece necessária. Não se alega
animação manual quadro a quadro ou aprovação estética de Pedro.

O KO baixa joelhos/cabeça, apoia as mãos e termina deitado, olhos fechados e
cauda recolhida. A pose final é mantida; não representa morte, desaparecimento
ou celebração. O espelhamento conserva a linha de chão. A transição de volta
ao desenho anterior será verificada com reanimação no jogo.

As poses são consideradas utilizáveis para **integração e revisão desta PR**,
em uma nova release 1.0.0; a versão de estudo 0.2.0 fica intacta. Produção aqui
significa o recurso escolhido explicitamente nesta branch, não aprovação humana
final. Não fazer merge antes da revisão independente e dos gates finais.
