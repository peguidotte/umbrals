# Folife: revisão independente do piloto

O revisor `foli_lifecycle_review` permite manter a integração somente em
draft. Sem merge/main, aprovação estética humana ou declaração de família
completa. Relatórios, verificações e painéis originais estão em
`artifacts/folife-independent-review/` na entrega de evidências.

O recorte preserva suficientemente a segunda forma v11: orelha serrada e
broto, colar, lâmina curta, chevron, cauda e postura de lebre. Os volumes
de patas/cauda e expressão diferem levemente. As composições RGBA não têm
franja vermelha opaca; a conclusão anterior era um falso positivo do filtro.

Os doze recortes são cópias exatas, sem perda de pixels com alpha >=128/240,
sem parte opaca de vizinho e com piso y=340. O pivô [150,340] foi definido
na integração e revisto no preview nativo. Nas duas orientações, a 118 px e
2,4×, o revisor não viu salto do chão ou deriva acumulada. O loop fecha sem
idle intermediário; o apoio duplo prolongado ainda merece avaliação estética.
O chevron, o colar e a coxa variam entre poses.

Os cortes de caminhada e recuperação para idle não duplicam cabeças, patas
ou lâminas. Há pequenos saltos de postura, e os olhos abrem no último corte.
O preview chama apresentação diretamente, com HP 60/60; não comprova regras.

A captura separada do jogo confirmou caminhada com 60/60, KO mantido com
0/60, reanimação com 21/60 e idle final. Eventos e rótulo Folife · 1 mantêm
UID 1; 16 checks, zero falhas. Não houve desaparecimento ou duplicação do
corpo na sequência útil. O final preto após encerrar o processo não é estado
adicional do jogo. O exercício usa comandos semânticos de produção e dados
isolados; não é prova de controles físicos ou cliques OS.

A medição do jogo registra cerca de 24,95 fps após os dois frames iniciais,
com p95 de parede 65,369 ms e máximo 253,388 ms. O MP4 tem 220 quadros em
10,96 s; as amostras do framebuffer não representam novos frames do motor.
A diferença para o vídeo anterior de Foli não prova correção de desempenho.
Cadência final e hardware alvo continuam sem aprovação.

O revisor não editou fontes, pins ou assets, nem executou engine ou testes.
Verso, efeitos próprios de lâminas, formas finais e regras novas não foram
aprovados por esses pareceres.
