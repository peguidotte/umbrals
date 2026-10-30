# Formação, trocas e combinações — estudos e proposta de efeitos

**Direção vigente:** [3×3, seis integrantes e três ações como hipótese](battle-3v3-direction.md).
O usuário pediu teto ativo fixo em três e retirou expansores de campo. As
comparações de dois/quatro ativos e recomendações abaixo são histórico; os
combos seguem pertinentes, agora com iniciativa por velocidade em D38 e alvos
por posição em D39/D40. D32 exclui
cartas dos reservas aptos do ciclo ativo, e D33 confirma troca por uma ação,
executada somente ao confirmar Conjurar. A proposta vigente está em
[batalha v0.4](battle-design-v0.4.md#reservas-e-trocas--direções-confirmadas).

Estado: **estudo de design, sem implementação**. Desenvolve a
[batalha v0.4](battle-design-v0.4.md). O usuário levantou reservas/trocas como
alternativa, agora comparando dois/quatro ativos e a direção anterior de até seis.
Confirmou a intenção de combinações causais com ordem predefinida, como água
aplicando Encharcado antes de um golpe elétrico com dano ampliado.

**Registro da entrevista anterior:** o usuário não escolheu quatro ativos com reservas.
Pediu cenários e concessões, destacando preocupação com muitos corpos em tela.
A recomendação inicial de quatro será confrontada com dois ativos; não converter
a pergunta anterior em aprovação. O limite de ativos e o uso de reservas estão
em reavaliação, preservando início com um e capacidade total base quatro/teto seis.

## Quantos em campo

| Modelo | O que favorece | Concessão |
|---|---|---|
| **Até quatro ativos; capacidade extra vira reserva** | Dupla de combo, protetor e suporte podem coexistir; reservas preservam integrantes e permitem adaptar a formação. Arena mantém quatro corpos por lado. | Acrescenta custo/timing de troca e regras para cartas suspensas. Reservas não são automaticamente uma melhoria de consistência. |
| **Todos ativos, quatro slots base até seis por expansores — direção anterior** | Cartas de todo membro vivo são utilizáveis; seis criaturas ficam presentes, sem camada de trocas. | Maior densidade visual e de HP/alvos; ampliar o time dilui compras e pode tornar os dois slots muito valiosos. |
| **Até dois ativos, com reservas** | Foco maior nos protagonistas, trocas e espaço visual. Duplas ainda sustentam preparação e execução de um combo. | Menos papéis simultâneos e mais rotação para reunir funções; exige redesenhar a pressão dos encontros e as cartas de reserva. |

Um ou dois ativos **não impedem** cartas e combinações. No 1×1, um mesmo dono
pode usar vários poderes, conforme D13, ou preparar um estado para a próxima
rodada. No 2×2, um pode preparar e o outro explorar. Quatro favorecem papéis
simultâneos; dois favorecem compromissos na formação e presença visual. Quantidade
de criaturas em campo não é um requisito matemático para combinações de cartas.

A concessão real dos dois ativos é perder conjurações com três/quatro donos
simultâneos, se só ativos agem. Cadeias com mais espécies podem atravessar
rodadas por estados persistentes e trocas, mas não equivalem a reunir todos
na mesma jogada. Testar se essa perda prejudica a promessa de combinações.

### Cenários para decidir com mais clareza

| Situação | Dois ativos | Quatro ativos |
|---|---|---|
| **Água + raio nesta conjuração** | Orvalho prepara e Faísca explora o mesmo alvo. Funciona no próprio turno. | A mesma dupla faz isso; outros dois papéis podem oferecer alternativas. |
| **Faísca ameaçada; quero Musgo para proteger** | Trazer Musgo exige retirar Orvalho ou Faísca. Pode sacrificar o combo imediato ou usar Encharcado aplicado antes. | Se Musgo já está entre os quatro, a disputa é entre gastar ação em proteção ou outro poder, sem mudar a formação. |
| **Preciso curar e atacar** | Concentrar funções em poderes versáteis ou trocar um parceiro; o slot é uma concessão estratégica. | Mais especialistas disponíveis, mas o orçamento de ações continua limitando o que de fato se executa. |
| **Chefe com ataque amplo** | Menos corpos/HP ameaçados e mais espaço para o golpe; menor variedade de alvos para provocar/proteger. | Proteção de grupo e distribuição de dano ganham valor; leitura e efeitos precisam preservar oito corpos/HP. |
| **Mão ruim e reserva** | No modelo de cartas do time inteiro, metade das cartas de quatro integrantes ficaria suspensa; risco importante de turnos sem resposta. | Com quatro integrantes todos estão aptos; esse problema aparece quando entram quinto/sexto como reservas. |

Exemplo com quatro ações hipotéticas: água (1) + raio (1) deixa duas para outros
poderes em ambos os formatos. No 4×4, somar tanque (1) e cura (1) pode preencher
todos os papéis na mesma jogada; testar se custos/ameaças ainda geram concessões.
No formato de dois ativos, aplicar Encharcado numa rodada e depois trocar Orvalho
por Musgo pode sustentar proteção + Descarga na seguinte, se o estado persistir.
Isso cria outra sequência de preparação, não ausência de combinação.

### Histórico: presença visual e primeira recomendação de teste

2×2 mostra quatro corpos, quatro HP e duas intenções; 4×4 mostra oito corpos,
oito HP e quatro intenções; o máximo anterior de 6×4 mostra dez corpos. Em todos
os casos continuam cartas, donos, estados e efeitos. Não medir apenas se os
sprites cabem: avaliar se reconhecemos quem agiu, quem foi atingido e a ligação
entre a pose, o golpe e a consequência.

**Recomendação após a preocupação visual: testar 2×2 primeiro, com 4×4 como
comparação**, sem fechar a formação de lançamento. A prioridade autoral de
criaturas memoráveis dá motivo para preferir inicialmente a hipótese que oferece
mais presença e respiro. O teste pode mostrar que quatro continuam legíveis e
acrescentam decisões suficientes para justificar a densidade. Não oferecer ao
jogador um seletor de tamanho de batalha apenas porque o protótipo compara ambos.

Comparar as imagens no mesmo viewport e, em protótipo, o exemplo água/raio e a
necessidade de proteção. A prancha de dois usa cartas dos ativos para isolar a
leitura visual; isso não aprova filtragem dinâmica nem resolve as trocas. Primeiro
provar o núcleo com uma formação inicial estável; depois testar o baralho e a
troca com reservas. O resolvedor deve tratar coleções de indivíduos, evitando
fixar a lógica em quatro por mera coincidência da primeira cena.

Dois ativos também podem produzir um baralho menor se só eles contribuírem:
na hipótese de seis cartas por dono, são 12 em vez de 24 com quatro. A frequência
dos combos muda; mão oito/ações quatro não são números aprovados que precisem
ficar iguais no balanceamento final. Manter o HUD comparável nas imagens serve
à leitura visual, não demonstra equivalência de dificuldade entre os formatos.

A [estratégia oficial de Pokémon sobre duplas](https://www.pokemon.com/uk/strategy/battle-tactics-speed-control-in-double-battles-in-pokemon-sword-and-pokemon-shield)
descreve combinações e entrada de um parceiro por troca; o
[guia oficial de batalha](https://diamondpearl.pokemon.com/en-us/trainersguide/fundamentals/battling/)
apresenta a concessão de trocar em vez de executar um golpe. A adaptação abaixo
usa o orçamento coletivo de ações do Umbral, não as mesmas regras de Pokémon.

## Estudo anterior: funcionamento possível das reservas

Proposta condicional: um integrante inicial; quatro vagas totais base; os
expansores permitem quinto/sexto integrante. Teto ativo de dois/quatro continua
em estudo. Escolher a
formação inicial entre encontros é gratuito. Quantidade de criaturas inimigas
permanece até quatro; reservas da IA não são incluídas automaticamente.

Troca voluntária custa **uma ação** como hipótese de protótipo e integra a
conjuração, resolvendo antes dos poderes. Essa possibilidade histórica de trazer alguém e jogar seus poderes na mesma
rodada não foi confirmada: a regra aceita só os compra na próxima compra normal. O integrante que sai não executa
poderes nessa conjuração. Propor no primeiro teste uma troca voluntária por
rodada, reavaliando a necessidade desse teto; ele não é um limite de poderes
por indivíduo. Cancelar o planejamento não consome ação ou sorteio.

Reservas preservam HP, melhorias e estados. Não recebem ataques comuns ou área
destinada aos ativos, não curam automaticamente e não fornecem auras de combate
por padrão. Estados persistentes continuam sua contagem/dano, evitando que uma
troca apague veneno. Técnicas que atingem reserva precisariam dizer isso. Um
trait de capacidade pode ser uma exceção de expedição, ativa enquanto o indivíduo
integra o time; não inferir que toda passiva funciona fora de campo.

Um ataque inimigo comprometido contra quem sai acompanha sua substituição,
atingindo quem entra; a regra fica explícita na prévia conforme a informação
permitida. Isso é remapeamento determinístico do alvo original, sem nova decisão
da IA. Não introduz alcance ou posições táticas nas fileiras visuais. Outras
exceções de alvo exigem texto próprio antes de entrar no catálogo.

Se um ativo cair, a proposta permite ocupar a vaga com uma reserva apta entre
rodadas, sem cobrar a troca voluntária e sem conceder ataque extra. Não declarar
derrota enquanto houver reserva capaz de continuar. Não reanimar o caído:
suas cartas seguem bloqueadas conforme D19. Timing e interações devem ser
prototipados antes de adotar essa regra.

### O problema importante: cartas da reserva

Uma hipótese simples de regras é **baralho do time inteiro**, com cartas de reserva
visíveis e suspensas até o dono entrar. Podem ser planejadas junto de uma troca
válida. A troca não compra, não filtra, não embaralha e não altera cópias/pilhas;
a mão continua renovando no fim da rodada. Cartas de quem saiu ficam suspensas.
Incapacitação é outro motivo de bloqueio, não uma forma de ativar a carta trocando.

Isso preserva conservação e permite usar imediatamente uma carta do recém-chegado,
mas tem um custo real. Com seis integrantes, seis cartas por dono e mão uniforme
de oito, duas reservas representam 12 das 36 cartas; a mão contém em média
`8 × 12/36 ≈ 2,67` cartas de reserva antes de qualquer remoção/evolução/nocaute.
São hipóteses numéricas, não medida de diversão. Avaliar se a flexibilidade da
troca compensa essa pressão junto das cartas de incapacitados.

Com dois ativos e seis integrantes, a mesma hipótese dá em média `8 × 24/36 ≈
5,33` cartas suspensas numa mão de oito. Não transportar a recomendação de quatro
ativos para dois sem rever esse custo. Reservas podem exigir uma solução de
baralho diferente; a escolha da formação precede sua aprovação.

Alternativa: comprar somente de ativos, retirando e reinserindo cartas ao trocar.
Isso exige regras adicionais de posição nas pilhas, entrada na mão e prevenção
de filtragem grátis; não adotar apenas porque parece mais limpo no HUD.

Reservas devem entrar em fatia posterior ao núcleo de HP/ações/combos. Medir
trocas que mudam uma decisão e mãos sem resposta, sem adicionar previamente
um catálogo de gatilhos de entrada/saída que obrigue a girar o time toda rodada.

## Ordem predefinida para combinar poderes

**D38 atualiza a proposta:** iniciativa baseada na velocidade de cada Umbral,
com aliados e inimigos podendo se intercalar. D23 mantém combinações causais e
resultado independente da ordem dos cliques. A proposta anterior de resolver
Manobra → todo Preparo → todo Impacto → resposta inimiga fica como histórico;
não garantir preparação antes de dano apenas por classificar uma técnica.

**Defaults recomendados por delegação, ainda sem validação de gameplay:** cada
poder selecionado entra na fila; técnicas comuns usam a velocidade do dono.
Exceções de prioridade são explícitas no poder. Trocas têm prioridade sobre
golpes comuns como proposta, mas só executam após Conjurar e custam uma ação.
Fixar iniciativa ao confirmar; mudanças comuns de velocidade valem na próxima
rodada. Desempates são estáveis na rodada, sem depender de cliques ou sorteios
na prévia. O [contrato atual](battle-design-v0.4.md#iniciativa-e-atributos) detalha
os defaults e separa confirmação de proposta.

### Exemplo numérico proposto

- **Chuva Curta**, de Orvalho: uma ação, prioridade normal; causa 4 de dano e
  aplica Encharcado até o encerramento da rodada seguinte.
- **Descarga**, de Faísca: uma ação, prioridade normal; causa 8 de dano, ou 16 se
  o alvo estiver Encharcado quando o golpe efetivamente executar.
- Com Orvalho a Velocidade 70 e Faísca a 50, água precede raio: **4 + 16 = 20**,
  se ambos puderem agir e o alvo continuar elegível.
- Com Faísca a 90 e o alvo inicialmente seco, raio precede água: **8 + 4 = 12**.
  Clicar água primeiro não muda o resultado. Acelerar Orvalho, reduzir velocidade
  de Faísca ou preparar Encharcado numa rodada anterior permite outras soluções.
- Um inimigo pode agir entre os dois. Nocaute, proteção ou limpeza de estado
  podem impedir a combinação; a prévia respeita a informação autorizada.

Encharcado binário, não consumido pela Descarga, é a hipótese inicial. Reaplicar
renova duração, sem empilhar multiplicadores. Duas Descargas elegíveis podem
aproveitar o estado, cada uma com seu custo. Não generalizar dano dobrado para
todos os golpes elétricos: é uma condição escrita nessa técnica. Números,
duração, resistências e fórmulas de atributos ainda precisam de protótipo.

D39 define superior/central/inferior, sem frente ou retaguarda. A técnica informa
se atinge uma posição, superior + central, central + inferior ou tudo. D40
confirma que o substituto recebe o golpe destinado à vaga que assume. Alcance
não é distância entre sprites; aproximar grupos na arte não altera a máscara.

Default proposto: eliminar o alvo não transfere o golpe seguinte para outra
vaga automaticamente. Uma posição vazia não recebe dano; um substituto apto na
posição é atingido. Custos da conjuração confirmada não são devolvidos por
interrupção. A execução e a prévia não devem revelar o plano oculto ao mostrar
se uma ação própria certamente acontecerá.

## HUD compacto solicitado

**Confirmado:** itens acessados por uma única mochila; rodada/ações ocupam menos
espaço. Proposta: rodada num chip discreto de canto; ações junto de Conjurar,
com número e pequenos marcadores. Quando houver seleção, distinguir custo
planejado de ações disponíveis sem depender só de cor. Retirar a grande placa
de título durante a batalha. Compra/descarte continuam com contadores pequenos.

A mochila abre um painel de itens com categorias/custos e fecha devolvendo foco.
Abrir/consultar é gratuito; somente confirmar um uso paga o custo de combate.
Escolher alvo, quantidade e efeito ocorre antes da conjuração. Não pôr frascos
individuais permanentemente no HUD. Sem ações/poderes junto de Resortear: D11
continua exigindo o passe integral. Este painel não foi implementado ou desenhado
aberto na prancha atual.

## O que observar no protótipo

As pranchas desta rodada ficam em
`artifacts/battle-formation-hud-20261016T030750Z/`, com originais, prompts,
hashes e limites registrados. Uma revisão de HUD mantém os seis corpos anteriores;
a comparação seguinte usa 2×2 e 4×4. A mão final de água/raio é a referência
comum de leitura, não uma garantia de compra ou de equilíbrio. As primeiras
gerações tiveram cartas extras; os intermediários permanecem preservados.

Combo água/raio deve resolver igual em toda permutação de cliques; prévia e
execução concordam sobre estado/bonificação de cada alvo. Troca não muda o plano
inimigo ou RNG e não compra cartas. Conferir custos, entrantes/retirados, KO com
reservas e conservação das instâncias. Em sessões humanas, observar se até três
ativos continuam legíveis, se a velocidade permite preparar/interromper combos,
se trocar resolve um problema e se a mochila
economiza espaço sem dificultar descobrir um consumível útil.
