# Disposição diagonal consistente — 1×1, 2×2 e 3×3

Estado: **brief de composição para conceitos**, sem implementação no Godot.
O usuário escolheu a imagem do pântano frio com Brasa como referência para esta
rodada. Refinar essa mesma imagem em três ocupações, mantendo cenário/câmera,
escala dos sprites, direção do confronto, ataque e HUD.

## Regra visual proposta

Cada lado tem seu próprio centro de formação. Distribuir os apoios ao longo de
duas linhas diagonais paralelas, sem desenhar linhas, círculos ou vagas vazias.
O jogador continua escolhendo de um a três ativos; as contagens de cada lado
são independentes, inclusive 1×3. As três imagens simétricas são comparação visual.

Hipótese de briefing, em frações da imagem de referência completa: centro aliado
`(0,32; 0,575)`, centro adversário `(0,745; 0,38)` e passo entre apoios
`(0,17; 0,065)`, refinados após observar a primeira prancha completa. Para cada lado, usar
`apoio(i) = centro + (i - (n - 1)/2) × passo`.

| Ocupação | Aliados: posição relativa do apoio | Inimigos: posição relativa do apoio |
|---|---|---|
| **1** | (32%; 57,5%) | (74,5%; 38%) |
| **2** | (23,5%; 54,25%), (40,5%; 60,75%) | (66%; 34,75%), (83%; 41,25%) |
| **3** | (15%; 51%), (32%; 57,5%), (49%; 64%) | (57,5%; 31,5%), (74,5%; 38%), (91,5%; 44,5%) |

São guias de geração, não medidas comprovadas das imagens nem coordenadas rígidas
de runtime. Na produção, avaliar envelopes de corpo/cauda/pose, pivô do chão,
margens e área útil do HUD; ajustar centro/passo como sistema. Não compensar
sprites grandes com zoom por quantidade ou deslocamentos arbitrários individuais.

- A mesma espécie conserva sua escala e orientação entre as três ocupações.
- Aliados olham para cima/direita em três quartos de costas; inimigos olham
  para baixo/esquerda em três quartos de frente.
- Nome/HP seguem o apoio e usam distância visual consistente; intenção fica
  acima do adversário, sem colidir com caudas/orelhas ou a borda.
- A câmera, o horizonte, a lua, o cenário e o espaço reservado às cartas ficam
  estáveis. O grupo menor se centraliza na própria área; não se aproxima do outro.
- A geometria é composição visual, sem introduzir fileiras táticas ou alcance.

## Comparação controlada

Brasa e Nivalume aparecem em todas as imagens. A versão de dois acrescenta
Orvalho e Cascário; a de três acrescenta Musgo e Ramal. O ataque é a mesma espiral
de brasas. Assim, mudar quantidade não exige trocar cenário ou linguagem visual.

O time aliado ilustrativo tem seis integrantes: Brasa, Orvalho, Musgo, Faísca,
Peregrumo e Velária. As reservas exibem cinco, quatro ou três retratos conforme
os ativos. Não duplicar o mesmo indivíduo nos dois grupos.

Manter a mesma mão de seis cartas de Brasa nas três imagens isola o estudo de
ocupação. Isso não decide política de compra/reservas nem impede que outros
integrantes tenham cartas. Custos, pilhas e três ações continuam dados ilustrativos.

## Estudo de escala dos evoluídos

Pedido explícito do usuário após a série de ocupação: seis evoluídos grandes
na diagonal e em confronto horizontal, mantendo a referência do pântano frio.
Horizontal significa times à esquerda/direita no campo; ambas são telas PC 16:9.

Comparar as mesmas famílias: Brasa/Ignivar, Orvalho, Musgo/Verdálio, Nivalume,
Cascário e Ramal. As formas visuais de evolução são propostas; nomes com `II`
são marcadores de estudo, sem aprovar novas espécies ou atributos. Preservar
cauda de abrigo, reservatório, santuário de casca, leque de gelo, pinça de âmbar
e galhadas como assinaturas familiares. Variar largura, altura e massa.

O teste deve ocupar mais espaço em tela, sem diminuir os evoluídos até a escala
das formas básicas nem afastar a câmera. Conservar a arena e o HUD; se necessário,
ajustar a formação inteira com margem para corpos/rótulos. A horizontal explora
triângulos abertos, com dois apoios atrás e um adiante. Não implica fileiras,
alcance ou mudança da formação opcional de um a três ativos.

Briefs e resultados desta extensão: `artifacts/battle-evolved-3v3-20261016T044037Z/`.

Na diagonal gerada, os seis corpos aumentam a ocupação da arena, com silhuetas
distintas de largura/altura. Verdálio fica próximo à faixa de cartas e o lado
inimigo tem pouco respiro entre leque/pinça/galhadas. As seis barras continuam
legíveis, mas animações de ataque/proteção podem exceder o envelope de repouso.
Manter margem de movimento no protótipo, não tratar esse encaixe como resolvido.

Na horizontal, os triângulos distribuem melhor as massas em altura e abrem o
corredor entre os times. Orvalho e Ramal ficam próximos ao HUD inferior; separar
melhor barras/cartas e testar a expansão das poses. As aparências foram usadas
como referência entre telas, mas contornos/poses variam: a comparação não prova
escala idêntica nem capacidade de seis envelopes máximos em movimento.

## Limites da verificação

A rodada seguinte compara elevação, eixo do confronto e formação interna no
[estudo de câmera](battle-camera-study.md). A horizontal elevada é recomendação
para protótipo, ainda sem escolha final do usuário; a preferência estética pela
diagonal permanece registrada. O refinamento também explora enquadramento um
pouco mais aberto e chão com menor contraste, sem mudar o tamanho do HUD.

Inspecionar contagem, chão, orientação, escala relativa, respiro entre corpos,
distância entre rótulos e consistência de cenário/HUD. As gerações aproximam o
brief; a posição exata e o movimento precisam de uma implementação com pivôs e
envelopes verificados no viewport. Não declarar layout determinístico, animação
ou balanceamento validados por imagens conceituais.
