# Câmera e disposição — estudo comparativo

Estado: **formato aprovado como alvo do MVP de batalha em D31**.
Data: 17/10/2026. Fatias documentais/visuais RM-BATTLE-15/16/17/18, ligadas ao marco 0.4.
O executável continua 0.3.0. O estudo começou pela preferência estética da
diagonal e pela hipótese de maior fluidez horizontal. Após comparar, o usuário
selecionou a horizontal elevada refinada e pediu proporções menores e formação
mais fechada/consistente. D30 aprofunda a seleção: cenário proporcionalmente
menor, trio quase alinhado e nova organização do HUD. Isso define a base visual;
interação e movimento continuam sem implementação nesta rodada. A imagem e o
[contrato visual aprovados](references/battle/00-aprovada/README.md) ficam no
[acervo central](references/battle/README.md), com todas as 41 referências. A
[pauta seguinte](battle-interview-next.md) passa às regras ainda abertas.

## O que a câmera precisa resolver

O jogador precisa reconhecer seis indivíduos, relacionar carta/dono/alvo e
acompanhar uma sequência causal de efeitos. Espaço entre times ajuda trajetórias;
espaço entre integrantes ajuda seleção, proteção, cura e ataques em área. Um
corredor vazio não resolve sozinho sobreposição de corpos, HP e intenções.

Separar três variáveis: **eixo do confronto**, **elevação do ponto de vista** e
**formação interna de cada grupo**. Um confronto esquerda/direita pode ter
profundidade e criaturas em três quartos. A diagonal também pode mostrar mais
chão e menos céu, liberando área útil sem reduzir o adulto à escala da forma base.

## Três briefs comparáveis

Mesmos seis evoluídos, pântano frio, espiral de brasas, HUD e mão de seis cartas.
Em todos, reduzir contraste e detalhes atrás dos corpos e deixar uma faixa
livre entre as barras mais baixas e as cartas. Reprojetar chão/corpos para cada
vista; não colar sprites laterais numa vista superior. Artes novas e sufixos II
continuam propostas, sem inclusão no catálogo.

| Estudo | Orientação artística da câmera | Formação | Hipótese / concessão |
|---|---|---|---|
| Horizontal elevada | Cerca de 35–40° acima do chão; pouca faixa de horizonte; projeção próxima de ortográfica. | Times esquerda/direita em triângulos abertos, leve inclinação do confronto. | Combinar rostos/silhuetas reconhecíveis, piso visível e centro livre; exige poses coerentes em três quartos. **Recomendação inicial.** |
| Diagonal alta | Cerca de 50–55° acima do chão; quase todo o campo é piso, sem céu. | Aliados abaixo/esquerda, adversários acima/direita, grupos em leque. | Separar apoios/efeitos no solo e preservar a direção diagonal; costas e topos ganham espaço, rostos podem perder presença. |
| Horizontal lateral | Cerca de 15–20° acima do chão; horizonte mais presente. | Times esquerda/direita, triângulos com profundidade curta. | Dar destaque às expressões e ao gesto de ataque; bichos altos e rótulos têm maior risco de se sobrepor. |

Graus são **alvos de direção de arte**, não medidas calibradas dos PNGs. Em 2D,
elevação depende do desenho/projeção do ambiente e das poses; girar Camera2D não
produz essa mudança. A geração pode alterar escala, cenário e contornos: o estudo
compara composições, sem isolar matematicamente uma única variável.

O primeiro resultado horizontal elevado ainda deixou os dois corpos dianteiros
próximos e muito detalhe no chão. O refinamento pede enquadramento um pouco mais
aberto, com redução coerente de aproximadamente 12–15% dos corpos no mundo,
mantendo os adultos e o tamanho do HUD. É uma alteração explícita de enquadramento,
não evidência de que só a elevação criou espaço. O rascunho fica preservado.

## Recomendação para o protótipo

Começar pela **horizontal elevada**, com dois grupos compactos e reconhecíveis,
mas corpos/rótulos separados; aproximadamente 18–22% da largura central livre de
corpos em repouso como guia, não regra garantida para toda animação. Manter rostos
visíveis em três quartos e pouca redução aparente de tamanho no fundo. Conservar
o espaço dos adultos quando houver só um ou dois ativos, recentralizando o grupo.

Dar cerca de 70–73% da altura à arena e 27–30% à mão/comandos. Dentro da arena,
reservar margem de movimento acima das cartas; os números são hipóteses de
composição. Seleção destaca dono e alvo; o restante pode perder um pouco de
contraste sem apagar estado relevante. Nome, HP e intenção ficam associados
visualmente ao indivíduo e não cruzam o corpo de outro.

Durante a decisão, câmera estável. Durante a resolução, antecipação curta,
trajetória/gesto e impacto local revelam quem fez o quê. Evitar cortes de câmera
rotineiros a cada carta; o combo precisa conservar referência espacial. Uma
pequena aproximação em eventos excepcionais é hipótese futura, com retorno à
mesma composição e opção de movimento reduzido. Corpo/efeito podem se expandir
temporariamente, mas voltar ao mesmo apoio; não redesenhar o layout a cada golpe.

## Inspirações e argumentos

- **Pokémon:** identidade da criatura depende de pose, silhueta e reação. Usar
  como princípio para mostrar rosto/gesto, sem assumir que uma câmera de duelo
  transfere automaticamente para seis criaturas e cartas.
- **Pirates Outlaws e Slay the Spire:** organização lateral e informação ligada
  ao adversário inspiram a leitura de alvos/intenções. O elenco simultâneo do
  Umbral exige mais espaço interno; essas referências não comprovam o nosso 3×3.
- **Balatro:** interface espacialmente estável e feedback concentrado no evento
  inspiram a mão e a sequência de resolução, sem tratar seu tabuleiro como uma
  solução de câmera para criaturas.

## O que observar antes de fechar

1. Apontar qualquer um dos três inimigos, inclusive o menor entre dois grandes,
   com o mesmo tamanho de viewport e controles nas alternativas.
2. Ler água → Encharcado → raio no mesmo alvo, cura entre aliados e ataque em área
   contra os três. Identificar emissor/alvos/resultado sem perseguir a câmera.
3. Testar as seis silhuetas grandes com expansão de caudas, galhadas, proteção e
   recuo. Registrar sobreposição de corpo, HP, intenção e faixa de cartas.
4. Comparar 1×3, 2×3 e 3×3, mantendo ocupação opcional, até seis no time e três
   ativos no máximo. A composição não introduz fileiras táticas ou alcance.

Imagens mostram o estado estático. Fluidez, seleção e leitura temporal precisam
de protótipo com as mesmas ações/animações em cada composição. Nenhuma câmera
fica aprovada pela recomendação inicial ou por uma geração visual.

## Evidência

### Direção atual — RM-BATTLE-17

O usuário destacou `base.png` da rodada anterior e especificou os ajustes:

- Reduzir a escala aparente dos elementos do ambiente para acompanhar os corpos
  menores, mantendo as proporções dos Umbrals escolhidos. Guia de arte: cenário
  cerca de 15–20% menor; não escalar o frame inteiro ou o HUD.
- Subir os integrantes superiores e os intermediários; recuar Verdálio para a
  esquerda e Cascário para a direita, para dentro de seus próprios grupos.
  **Substituir os triângulos** por duas formações quase retas, com leve curvatura
  para dentro. Usar mais o piso superior e preservar níveis espelhados.
- HUD em quatro zonas da esquerda para a direita: **grade de reservas → mão →
  ações/Conjurar/Resortear → mochila/compra/descarte**.

Guias de apoio em frações da imagem completa: Ignivar `(23%;24%)`, Verdálio
`(25,5%;42%)`, Orvalho `(21,5%;60%)`; Nivalume `(77%;24%)`, Cascário
`(74,5%;42%)`, Ramal `(78,5%;60%)`. A pequena saliência central é composição,
sem introduzir fileiras táticas. São coordenadas de briefing, não runtime.
Rótulos podem ficar um pouco para fora de cada formação para proteger silhuetas.

A grade solicitada é **duas linhas de três células**, à esquerda das cartas.
Interpretação para o conceito: seis espaços visuais não aumentam a capacidade
do time. No exemplo com três ativos e seis integrantes, mostrar **três reservas
reais e três células vazias**. Não inventar seis reservas além dos ativos.
Seis cartas, mochila única e orçamento compartilhado ilustrativo permanecem.

Prompts, imagens e revisão: `artifacts/battle-aligned-hud-20261017T194420Z/`.
A recomendação anterior de barra horizontal não foi escolhida; a nova ordem
explícita do usuário prevalece. Interação e margens em movimento seguem abertas.

Revisão estática: a imagem amplia a leitura do ambiente e recua os integrantes
centrais, usando mais o piso superior. Os grupos ficam mais verticais; Ramal ainda
abre mais para fora e os inferiores ficaram abaixo do guia. Não há simetria ou
escala exata comprovada. O HUD tem as quatro zonas na ordem solicitada, seis cartas,
três retratos e três células vazias. Sinais de mais nas vazias são placeholders
visuais, sem novo controle/capacidade aprovado. Conferir HP/carta elevada e os
envelopes em movimento no protótipo.

### Refinamento selecionado — RM-BATTLE-16

O usuário escolheu `horizontal-elevada.png` e pediu reduzir um pouco mais os
Umbrals, aproximar cada trio e comparar HUDs caso útil. Manter a câmera e o
enquadramento selecionados. Guia de arte: redução adicional de 10–12% de
largura/altura dos corpos, preservando proporções adultas e tamanho da UI.

Dois triângulos espelhados com centro vertical comum. Guias dos apoios em
frações da tela: aliados Ignivar `(20%;36%)`, Orvalho `(20%;58%)`, Verdálio
`(33%;47%)`; adversários Nivalume `(80%;36%)`, Ramal `(80%;58%)`, Cascário
`(67%;47%)`. Igualar níveis e passo das formações, não dimensões das espécies.
São guias para o gerador; verificar envelopes e não prometer coordenadas exatas.
Menor espalhamento dentro dos times deve abrir espaço para ataques/recuos sem
aproximar os dois grupos entre si. Nomes/HP mantêm tamanho e acompanham os donos.

Comparar a mesma formação com HUD de referência, mão central compacta com
comandos à direita e mão central com barra horizontal inferior. Seis cartas,
três reservas, mochila única e três ações ilustrativas permanecem iguais.
Variações de HUD são propostas, sem seleção automática pelo gosto da formação.
Prompts/resultados: `artifacts/battle-compact-formation-20261017T193204Z/`.

Na primeira geração, a escala ficou muito abaixo da redução discreta pedida.
O rascunho foi preservado e uma correção recuperou a presença das formas adultas,
mantendo o agrupamento. A base corrigida tem seis corpos separados, trios mais
fechados e uma faixa livre sob os HPs inferiores. Posições/escalas continuam
aproximadas pelo gerador, sem equivalência pixel a pixel ou pivôs implementados.

Revisão dos HUDs: os dois preservam a formação visual e as contagens. A mão
centralizada com comandos à direita mantém praticamente a altura do dock atual;
os ícones de compra/descarte ficaram semelhantes e devem se diferenciar melhor.
A barra horizontal inferior organiza reservas/itens/pilhas/comandos em uma faixa
e é a recomendação da IA para aprofundar. As cartas sobem um pouco nesse conceito;
isso não comprova maior altura útil de arena. Ambas exigem teste de carta elevada,
animações e legibilidade em viewport. A escolha de HUD ainda pertence ao usuário.

### Estudo anterior — RM-BATTLE-15

Prompts, PNGs originais copiados, manifesto e revisão:
`artifacts/battle-camera-study-20261017T191245Z/`.
As observações abaixo diferenciam o brief daquilo que cada imagem efetivamente
apresenta.

Revisão concluída: a horizontal elevada refinada abre o centro e reduz o contraste
do piso, conservando personagens grandes em relação à interface. O ganho também
vem da redução de escala no mundo; não atribuir tudo ao ângulo. Na diagonal alta,
o piso ganha presença, mas o trio aliado continua numa linha rasa e Verdálio fica
próximo às cartas. Na lateral, faces/gestos se destacam, com menor separação em
profundidade e informação mais apertada entre Nivalume e Cascário. A recomendação
continua horizontal elevada para o primeiro protótipo, com margem inferior a
refinar e checagem em movimento. O manifesto preserva também o rascunho.
