# Batalha do Umbral — proposta para a v0.4

Estado: **alvo visual aprovado; primeira fatia de gameplay integrada e validada localmente**. Ver [escopo implementado e evidências](battle-implementation-v0.4.md). O executável
continua 0.3.0. O [roadmap](roadmap.md) registra as decisões e os marcos; este
documento desenvolve suas mecânicas e exemplos. Decisões confirmadas orientam o
protótipo; custos e efeitos ainda propostos não são balanceamento comprovado.

O [formato do MVP](references/battle/00-aprovada/README.md) está escolhido em D31:
horizontal elevada, grupos quase alinhados e HUD em quatro zonas. Todas as imagens
estão no [acervo de referências](references/battle/README.md). A [próxima entrevista](battle-interview-next.md)
registra as recomendações aceitas: mão base seis modificável, repertório inicial,
entrada de cartas após troca, reposição gratuita e reanimação para agir na próxima rodada.

O [estudo de naturezas, condições e reações](natures-status-reactions-v0.4.md)
separa os efeitos já executados dos defaults de protótipo e registra D41–D43
confirmadas: reações/resistências por espécie, natureza secundária em formas
específicas e controle por enfraquecimento/iniciativa.
Encharcado + raio já funciona; um estado Eletrificado próprio ainda não existe.

## Direção do conjunto

A formação escolhida é **até três ativos por lado e seis integrantes no
time**, começando com um. O jogador pode manter um ativo e cinco reservas contra
três adversários; não há preenchimento obrigatório do trio. O [brief 3×3](battle-3v3-direction.md) sucede a
comparação 2×2/4×4 e a expansão para seis em campo. Nenhum item, relíquia ou
espécie aumenta o teto de três ativos. Três ações compartilhadas é a hipótese
inicial sugerida; possíveis ampliações por relíquias continuam em design.

Itens para editar o baralho, HP individual, intenção parcial e passe integral
para resortear permanecem. D32 exclui cartas dos reservas aptos da mão, compra,
descarte e embaralhamento ativos. D33 confirma troca voluntária por uma ação,
planejada e executada somente ao confirmar Conjurar. Quem entra contribui na
próxima compra normal. D36 fixa mão base seis, modificável por itens e Umbrals;
D37 confirma reposição gratuita entre rodadas e agir só na rodada após reanimar.
O algoritmo de reinserção das cartas continua como proposta de protótipo.

**D38–D40:** iniciativa baseada na velocidade individual, três posições em linha
por lado (superior, central e inferior), sem frente/retaguarda, e golpes que
continuam destinados à vaga quando entra um substituto. A disposição lateral
dos times permanece; os alcances podem ser individual, superior + central,
central + inferior ou todas as posições. As posições têm função nos alvos,
embora não forneçam cobertura ou prioridade defensiva por si mesmas.

A direção desta rodada é **HP individual e um único orçamento de ações**.
Isso combina proteção de alvos, ataques em área, provocação e reanimação com a
construção de combinações. Vida individual é a direção preferida apresentada pelo
usuário. O usuário confirmou nocaute com possibilidade de reanimar e escolha de
resgatar/sepultar depois, sem morte definitiva automática a 0 HP.

No MVP, fôlego é o HP compartilhado e energia é um recurso separado para pagar
poderes. Na proposta, HP mede sobrevivência e ações medem o que se pode executar
na rodada. Não chamar HP de energia. **O usuário confirmou ações como único
recurso de execução**, com custos variáveis para poderes e consumíveis táticos;
energia separada sai do contrato futuro. A mão base é seis; três ações por rodada
continuam como hipótese numérica de protótipo.

## Um turno legível

1. Cada um dos até três adversários apresenta a informação autorizada.
   **Parcial confiável é o padrão escolhido:** categoria, sem pressupor golpe,
   alvo e dano exatos. Oculto e completo serão projeções do mesmo plano
   pré-calculado. O [contrato configurável](intent-visibility-design.md)
   define campos propostos e a configuração aceita: todos os modos disponíveis
   desde o início, com mudanças comuns valendo na rodada seguinte.
2. O jogador examina a mão e monta a conjuração dentro do orçamento de ações.
   Poderes e consumíveis de combate que exigem alvo mostram a escolha antes da
   confirmação.
3. A prévia separa efeitos conhecidos de resultados condicionais. Um poder pode
   ser impedido por nocaute ou outro efeito antes de sua execução. Intenções e
   resultados adversários usam certezas, intervalos ou desconhecido conforme a
   política de informação; não revelar um ataque oculto pelo HP futuro exato ou
   por sua posição numa fila completa de ações.
4. Confirmar reúne poderes, trocas e intenções já comprometidas dos dois lados.
   A resolução considera a velocidade de cada Umbral (D38), podendo intercalar
   aliados e adversários; não depende da ordem dos cliques. Não presumir que o
   jogador executa todas as cartas antes de receber ataques.
5. Encerrar a fila da rodada, processar os efeitos finais e oferecer reposição
   após nocaute, se necessária. Cartas da mão vão ao descarte e uma nova mão é
   formada conforme o ciclo escolhido.

**D23 confirma combinações causais com ordem predefinida; D38 acrescenta velocidade.**
Uma técnica de água pode aplicar Encharcado antes de uma técnica elétrica que o
aproveita, se a ordem efetiva permitir, mesmo selecionadas na ordem inversa.
A antiga proposta de todo Preparo preceder todo Impacto não é a regra vigente.
O [estudo](formation-and-combos-study.md#ordem-predefinida-para-combinar-poderes)
define o experimento e os limites de resolução. Não alterar silenciosamente
o contrato do executável 0.3 ao documentar essas regras futuras.

### Iniciativa e atributos

**Confirmado em D38:** cada Umbral tem atributos individuais, incluindo
Velocidade, que participa da ordem de atuação. O catálogo/fórmula ainda não
estão definidos. Recomenda-se começar com HP máximo, Ataque, Defesa e Velocidade;
natureza, trait e passiva continuam dimensões próprias. Separar atributos
numéricos de condições temporárias como Encharcado ou Lentidão.

**Defaults recomendados para o protótipo, desenvolvidos por delegação:**

- Cada poder escolhido gera uma ação na fila comum dos dois lados; não reservar
  uma resposta inimiga inteira para depois do jogador nem impor um poder por dono.
- Técnicas normais usam a velocidade do dono. Exceções de prioridade devem ser
  explícitas no efeito; não tornar toda água automaticamente mais rápida que raio.
  A troca voluntária tem prioridade sobre golpes comuns como proposta, mantendo
  seu custo de uma ação e execução apenas após Conjurar.
- Fixar os valores de iniciativa para a rodada ao confirmar. Alterações comuns
  de velocidade valem na próxima rodada; um efeito que reordene a atual precisa
  dizer isso. Empates entre donos usam desempate semeado, estável nessa rodada;
  poderes empatados do mesmo dono seguem ordem de execução definida no catálogo,
  exibida no planejamento. Cliques e prévias não sorteiam ou mudam a ordem.
- Um dono incapacitado antes de agir não executa os poderes restantes. O
  encerramento normal da mão continua, sem devolver ações ou cartas por padrão.

Exemplo proposto, com técnicas de prioridade normal: Orvalho (Velocidade 70)
aplica água antes de Faísca (50), permitindo o bônus elétrico. Com Faísca a 90,
o elétrico sai primeiro e não recebe um Encharcado ainda ausente. É possível
acelerar Orvalho, reduzir a velocidade de Faísca ou preparar água numa rodada
anterior, se a duração permitir. Preparação sempre primeiro é uma alternativa
histórica; estes exemplos não garantem execução diante de interrupções inimigas.

O orçamento e a inteligência adversária ainda serão prototipados; ter três
corpos não implica três ataques gratuitos mais habilidades fora do anúncio.
Um chefe pode aparecer sozinho ou com companheiros, com ações próprias claramente
mostradas. O teto ativo da direção atual é três por lado, conforme D22. A composição precisa dar
presença aos participantes em vez de reduzi-los a ícones pequenos; validar em cena
a composição aprovada em D31, mantendo legibilidade no elenco máximo. Não exigir simular um baralho oculto completo da IA antes de
provar que intenções, alvos e respostas são interessantes.

**Resortear / passar:** substitui a jogada inteira. Não resolve poderes ou
consumíveis de combate junto com a troca. O inimigo executa sua intenção normal,
e a mão é renovada para a rodada seguinte. Não é dano artificial cobrado pelo
botão: ataque, defesa ou preparação inimiga seguem a intenção anunciada. A rodada
e seus efeitos avançam; não pode ser usado para congelar o combate ou obter
compras gratuitas. A interface deve mostrar essa consequência antes de confirmar.

## HP individual, proteção e nocaute

Cada Umbral tem HP, proteção e estados próprios. O time perde quando não houver
nenhum membro capaz de continuar; uma reanimação precisa acontecer antes do fim
da batalha para impedir essa derrota. Não há uma barra de vida adicional do time.

**D39 — alvos por posição:** cada lado tem superior, central e inferior, sem
frente/retaguarda. Poderes podem escolher uma vaga individual ou cobrir superior
e central, central e inferior ou todas; o conteúdo explicita lado e máscara.
**D40:** se Brasa sai e Musgo entra na mesma vaga, Musgo recebe o golpe destinado
àquela posição. A troca não cancela o ataque nem faz a IA escolher outro plano.
Vale para alvo individual e para quem ocupar uma posição de um golpe em área.

Defaults propostos: posições mantêm identidade com um/dois ativos, sem comprimir
ou renumerar alvos após nocaute. Vagas vazias não recebem dano e não transferem a
parte perdida de uma área para outra posição. Formação entre encontros pode ser
ajustada gratuitamente; movimentar um ativo para outra vaga durante a batalha
não é uma ação incluída nesta fatia. A apresentação adapta o espaçamento sem
transformar a ausência de um corpo em uma mudança secreta de alcance.

**Provocar** redireciona ataques individuais elegíveis;
um ataque em área continua ameaçando o grupo. Golpes que ignoram provocação
precisam anunciar isso. Recalcular o alvo de um inimigo após uma mudança deve
seguir uma regra determinística que a prévia consiga explicar.

Isso dá ao tanque uma função concreta: escolher receber uma ameaça para manter
vivo o Umbral que prepara a combinação. Proteção, cura e provocação passam a
disputar ações com o dano.

**Decisão confirmada para 0 HP:** incapacitar, permitindo reanimação. O usuário
escolheu que **as cartas do indivíduo permaneçam na mão e no ciclo**, bloqueadas
enquanto ele estiver caído. Preservar dono, instâncias e melhorias. Não retirar
suas cartas das compras nem repor as vagas gratuitamente. A UI identifica o dono
incapacitado e impede conjurar sem consumir estado.

No fim de um turno normal, essas cartas vão ao descarte junto com as outras,
conforme D14, e podem voltar em compras posteriores. Se não houver jogada útil,
passar/resortear renova a mão ao custo do turno inteiro. Não presumir que a troca
garanta uma mão utilizável. Reanimar permite voltar a usar os poderes **na rodada
seguinte**, sem duplicar cartas ou devolver cópias removidas por itens (D37).
Na rodada da reanimação, o dono volta a estar vivo/protegível, mas suas cartas
continuam indisponíveis para conjurar.

Resgate, repouso e reanimação precisam ter custo/oportunidade na expedição;
retornar automaticamente com HP cheio retiraria parte do valor da proteção.
Valores e frequência serão prototipados. Nocaute, derrota e morte definitiva são
regras diferentes e não devem ficar implícitas na mesma palavra.

**Sepultar ou abandonar** é uma boa direção narrativa para eventos posteriores:
despedir-se encerra a presença daquele indivíduo na run e pode criar um eco
futuro, favorável ou hostil conforme o evento. A escolha mostra o que será
perdido. O códice pode guardar a memória, preservando D01; não transformar isso
silenciosamente em coleção permanente de indivíduos. Recompensas não devem
incentivar matar companheiros repetidamente para gerar recursos.

## Ações e participação

**Recurso único confirmado:** ações pagam poderes e consumíveis táticos. O
princípio aprovado usa uma ação para efeitos simples/consumíveis e permite custos
maiores para golpes pesados, sem outro medidor de energia. O custo exato de cada
técnica depende do catálogo. Consumíveis de preparação usados fora da batalha
não gastam ações de combate. Exibir o custo na própria opção.

Nova hipótese numérica sugerida pelo usuário: **três ações do grupo por rodada**, com ampliações por relíquias a testar.

O usuário confirmou **não impor um teto fixo de cartas por indivíduo**. É possível gastar
todas as ações com um único Umbral, enquanto a composição do time, as compras,
os custos e as ameaças dão razões para distribuir a jogada. Isso mantém espaço
para runs solo, duplas e times completos.

Um chefe pode pressionar essa especialização sem a tornar impossível. Exemplo:
**Vigília dos Espinhos** anuncia retaliação após a terceira conjuração do mesmo
indivíduo na rodada. O jogador pode distribuir poderes, proteger o especialista
ou aceitar o dano para concluir sua combinação. Texto e contador aparecem antes
da confirmação. É uma proposta de comportamento, não uma habilidade implementada.

O teto de duas cartas e a sobretaxa após a terceira foram alternativas
apresentadas e não escolhidas nesta rodada. Não reintroduzi-las como regra base
sem motivo novo. A punição de um chefe específico continua possível, anunciada e
com respostas jogáveis.

Não usar uma proibição de chefe que torne uma composição legal incapaz de jogar
sem antecipação e respostas disponíveis. Se houver limites rígidos especiais,
eles precisam de preparação de rota e formas de adaptação.

## Reservas e trocas — direções confirmadas

**D32:** cartas dos reservas aptos ficam suspensas fora das zonas ativas. Não
entram no embaralhamento, não podem ser compradas e não aparecem como poderes
utilizáveis. Preservar dono, instâncias, cópias removidas e melhorias.
**D33:** cada troca voluntária custa uma ação compartilhada. Selecionar apenas
agenda; ela executa junto da conjuração após confirmar Conjurar. Cancelar o
planejamento não troca corpos, não compra cartas e não consome RNG.

**Recomendação aceita:** quem entra contribui com cartas a partir da próxima
compra normal, sem compra imediata ou poderes emprestados durante o planejamento.

Proposta de ordem, compatível com D38: resolver trocas com prioridade sobre
golpes comuns. Dentro de uma mesma prioridade, usar velocidade.
Um integrante enviado à reserva não conjura nessa mesma resolução; a interface
impede planejar seus poderes junto da própria saída. Essa prioridade e essa restrição
específica continuam propostas; custo, confirmação, próxima compra e receber o
golpe na vaga do substituído (D40) estão definidos.

Proposta de conservação do ciclo: na primeira entrada, inserir as cartas daquele
dono sem reembaralhar a pilha já existente; randomizar somente o lote novo após
confirmar. Ao sair e voltar, restaurar o estado de compra/descarte das mesmas
instâncias, sem recuperar cartas já gastas nem reiniciar o ciclo. Cartas em mão
do dono que sai seguem o encerramento normal da mão, sem reposição imediata.
A regra precisa de casos de entrada/saída/retorno antes de implementação.

**Incapacitados não são reservas aptos.** D19 permanece: seus poderes continuam
nas zonas ativas, bloqueados, até reanimação; retirar o corpo para repor a vaga
não autoriza limpar a penalidade de cartas gratuitamente. A transição entre
estados precisa preservar esse contrato, sem generalizar a exclusão dos reservas
para todo dono que deixa a arena.

**D37 — reposição após nocaute confirmada:** entrada sem custo de ação, entre
rodadas e depois de terminar toda a fila dos dois lados (atualização de iniciativa
em D38). Repor vagas não obriga preencher
o trio; se todos os ativos caíram e existe reserva apta, escolher ao menos um
para continuar. Não interromper a fila para absorver golpes com
novas entradas gratuitas. A troca voluntária de alguém apto continua custando
uma ação. A gratuidade da reposição não remove cartas bloqueadas por D19.

**D37 — reanimação confirmada:** reviver nesta rodada e agir na próxima.
Exemplo: Brasa a 0 HP recebe uma poção e volta a estar vivo/protegível; Bola de
Fogo continua indisponível nessa conjuração. Seus poderes ficam utilizáveis na
rodada seguinte, caso ele esteja apto e em campo. Reanimar não compra cartas,
não traz cópias do descarte para a mão nem coloca automaticamente uma reserva
em campo. Custos, HP recuperado e acesso a um alvo fora do campo serão detalhados
por efeito; não são consequência automática desta escolha de timing.

## Cartas por captura, mão e consistência

**D36 — direção confirmada:** mão base de **seis cartas**, podendo aumentar ou
diminuir por efeitos de **itens e Umbrals**. A recomendação de três poderes
iniciais por integrante, com duas cópias de cada (seis cartas por dono), foi aceita.
Isso substitui a hipótese anterior de mão oito em D34.
Três ações compartilhadas permanece a hipótese existente. Inspirar-se na separação
entre opções vistas e cartas jogadas de Balatro; os números precisam funcionar
com os donos e custos do Umbral, não reproduzir seu baralho de naipes/valores.

Com todos aptos, sem aprendizado extra ou cartas bloqueadas:

| Ativos | Cartas elegíveis | Compra inicial máxima |
|---|---:|---:|
| 1 | 6 | 6 |
| 2 | 12 | 6 |
| 3 | 18 | 6 |

A tabela usa a mão base, sem modificadores. Tamanho da mão é quantidade de
opções compradas, não quantidade de ações ou de ativos. Um efeito de mão +1
permite comprar até sete, se houver instâncias suficientes; mão −1 permite até
cinco. Os itens continuam externos ao baralho. Um Umbral pode alterar essa
capacidade por um efeito explícito, sem ganhar cartas ou ações automaticamente.

Proposta de aplicação dos modificadores: calcular a capacidade na próxima compra
normal. Uma alteração durante a resolução não compra cartas imediatamente nem
exige descarte aleatório da mão atual. Limites, empilhamento e se cada efeito de
Umbral exige presença em campo precisam constar no texto do efeito e ser
prototipados; o usuário não fixou esses detalhes.

Os seis integrantes do roster não geram 36 cartas elegíveis quando metade está
na reserva. Capturar amplia as alternativas de formação; só passar a integrar o
campo altera o conjunto de compra. D19 pode acrescentar cartas bloqueadas de
incapacitados; a tabela acima não cobre esse estado.

Comparação quantitativa preservada de D34: a mão base seis reduz a leitura por
rodada e deixa ampliações de compra como possíveis recompensas. Em uma compra
uniforme de 18 cartas sem reposição, com duas cópias de
cada um de dois poderes específicos, a chance de ver ambos é cerca de **29,9% com
seis** e **48,0% com oito**. Isso mede compra, não custo viável, execução de combo,
balanceamento ou diversão. Cálculo: `1 - 2*C(16,h)/C(18,h) + C(14,h)/C(18,h)`.
Relatório em `test-results/design/battle-deck-20261018T031514Z/math.json`.

A compra respeita instâncias existentes: um único dono com seis cartas não
produz duplicatas para preencher uma mão ampliada. Nenhuma carta de reserva apta
é comprada. Aprender permite adicionar ou substituir poderes; evoluir melhora
as cópias existentes, sem inflar automaticamente o baralho. Essas recomendações
foram aceitas. Oferecer uma nova assinatura como escolha de adição/substituição
é um detalhamento proposto. Remoções devem persistir através de trocas/evolução;
quantidades e custos de cada oferta ainda exigem protótipo.

### Modelo de compra escolhido e alternativas avaliadas

| Modelo | Funcionamento | Benefício / concessão |
|---|---|---|
| **Ciclo visível — confirmado pelo usuário** | Embaralhar a pilha no início do encontro. Comprar a mão; cartas usadas e não escolhidas vão ao descarte ao fim da rodada. Reembaralhar o descarte apenas quando a pilha acabar. | As cartas ainda não vistas aparecem antes de voltar a embaralhar. A edição afeta a frequência de retorno, e o jogador entende o ciclo. Obriga a abrir mão de uma carta não usada, salvo efeitos de retenção explícitos. |
| **Reembaralhamento com memória — não escolhido** | A cada rodada, reunir cartas elegíveis e sortear sem reposição uma nova mão; uma carta não vista ganha peso até aparecer. | Aproxima a ideia inicialmente sugerida, mas a frequência fica menos intuitiva e o descarte deixa de informar a espera. Ficou como alternativa, sem implementação prevista. |
| **Mão persistente — não escolhida** | Manter cartas não usadas e comprar somente as que saíram. | Permite guardar uma combinação; cartas fracas podem ocupar espaço por várias rodadas. A regra futura de retenção precisa ser explícita e não substituir o ciclo escolhido. |

No ciclo visível, 18 cartas elegíveis e mãos novas de seis permitem ver o conjunto
em três compras, antes de repetir o ciclo, sem efeitos extras. Isso garante
oportunidade de encontrar as cartas, não uma boa combinação ou uma vitória.

Se escolhermos memória ponderada, um protótipo simples seria
`peso = 1 + min(rodadas_sem_aparecer, 3)`, zerando a espera quando a carta aparecer.
Os pesos são congelados no início da compra e o sorteio é sem reposição dentro
da mão. É uma hipótese reproduzível, não garantia de frequência ou de ausência de
azar. Estado de espera e RNG devem sobreviver ao save; a prévia não sorteia nada.
Comparar esse modelo com o ciclo antes de criar camadas de correção de azar.

Itens e relíquias também podem oferecer controle explícito: reter um poder,
buscar uma carta específica, melhorar compra ou garantir a assinatura em um
momento definido. Assim, a consistência vira parte da build.

## Categorias de itens

| Categoria | Onde fica / duração | Papel e exemplos propostos |
|---|---|---|
| **Consumíveis** | Bolsa externa com três slots como hipótese; desaparecem ao usar. | Táticos: curar um alvo, reanimar, limpar estados, proteger uma jogada. Preparação: remover uma cópia, transformar um golpe ou duplicar uma carta fora da batalha. São usos da mesma categoria, com contexto e custo indicados. |
| **Relíquias** | Efeitos persistentes e globais durante a run, fora da mão e das pilhas de cartas. | Alterar regras de sinergia, cura, compra, economia ou capacidade. Exemplo: um sino concede proteção ao aliado mais ferido quando o grupo aplica queimadura. Quantidade de slots permanece em aberto. |
| **Artefatos** | Equipados em um indivíduo, fora do baralho; um slot por Umbral na hipótese inicial. | Especializar função, modificar condições/custos de um poder conhecido ou a interação de uma passiva. Exemplo: um núcleo modifica uma Descarga já aprendida por Faísca; equipar o núcleo não cria a carta. |

**Categorias e separação confirmadas pelo usuário:** todos os itens ficam fora
do baralho. A quantidade de slots, custos e exemplos de efeitos continuam
propostas. Poções de emergência e ferramentas de remoção ficam disponíveis na
bolsa; relíquias e artefatos atuam como modificadores externos. Um item pode
alterar a composição do baralho sem se tornar uma carta dentro dele.

## Aprendizado e progressão dos poderes

**D17 confirmada:** o baralho contém poderes, que podem ser comprados, trocados,
aprendidos ou evoluídos. Todo poder pertence a um integrante atual do time.
Artefatos não acrescentam poderes temporários ao baralho simplesmente por serem
equipados. A proposta anterior de Núcleo de Trovoada que criava uma carta foi
substituída por este caminho próprio de aprendizado.

**Compatibilidade confirmada em três camadas:**

| Camada | Quem pode aprender | Exemplo de design |
|---|---|---|
| **Universal** | Qualquer Umbral que atenda requisitos gerais explícitos. | Concentrar: preparação genérica para uma técnica posterior. |
| **Natureza** | Integrantes da natureza correspondente, como Fogo ou Raio. | Bola de fogo para Fogo; Arco elétrico para Raio. |
| **Espécie / linhagem** | A espécie e suas evoluções. | Uma técnica de Brasa pode se transformar com Ignivar, preservando sua identidade e dono. |

Os exemplos são propostas; a classificação final dos poderes atuais será
revisada. Uma evolução pode transformar o poder específico da linhagem, conforme
a direção do usuário. Definir requisitos de aprendizado não implica criar uma
tabela ampla de vantagens elementais ou uma nova natureza adicional.

Uma oferta deve mostrar quem pode aprender, quantas cópias entram ou mudam,
quais cartas serão substituídas e o custo. Comprar, trocar e evoluir têm efeitos
distintos: adicionar aumenta o repertório; substituir muda a composição sem
necessariamente aumentar o tamanho; evoluir altera uma técnica já aprendida.
O comportamento exato das cópias ainda será desenhado.
Retirar um artefato não apaga uma técnica que o indivíduo aprendeu por esse
caminho independente. Substituir o indivíduo continua retirando seus poderes.

### Lojas entre runs e durante a expedição

O usuário pediu lojas **entre runs** para aprender e evoluir golpes. Registrar
isso como uma loja do Refúgio, separada dos mercadores/treinadores da expedição;
não reinterpretar a frase silenciosamente como apenas entre batalhas.

Existência e função de ensino/melhoria estão direcionadas. **O que a compra
preserva está em aberto:** desbloqueio de técnica/variante no catálogo, melhoria
permanente de golpes iniciais ou preparação somente para a próxima run.

Recomendo o Refúgio liberar novas técnicas e variantes como possibilidades
permanentes, enquanto o indivíduo aprende/especializa seus poderes na run. Uma
variante evoluída pode ser uma nova escolha com concessões, sem aumentar
automaticamente o dano de todos os futuros times. Isso é coerente com D01, mas
não equivale à aprovação do usuário dessa política de persistência. Se preferir
progressão permanente de força, explicitar a curva e a separação perfil/run.

## Histórico das composições visuais

A direção vigente é a [exploração 3×3](battle-3v3-direction.md). As pranchas
abaixo registram a evolução da conversa; quantidades antigas não são limites atuais.

O primeiro conjunto ilustrado foi **integralmente rejeitado pelo usuário**:
arte complexa demais e composição sem espaço para adversários com quatro
Umbrals. Seus originais permanecem preservados em
`artifacts/battle-concepts-20261015T033821Z/`; não são alvos aprovados.

A direção corrigida é **2D simples, com referência em Pokémon e Balatro**.
Pixel art de silhueta clara e poucas cores é a interpretação adotada para a nova
exploração. O usuário escolheu a primeira composição como base de trabalho. Criaturas e
golpes têm prioridade; impacto vem de antecipação, deslocamento, poucos frames,
som e efeitos curtos legíveis, sem ilustração realista ou partículas que escondam
os participantes. A floresta pode ser indicada por camadas simples.

Foram geradas três novas pranchas, cada uma mostrando desktop e celular
horizontal, com **quatro aliados e quatro adversários**, oito HP individuais,
intenções, oito cartas e bolsa externa. A numeração abaixo vale somente para as
três últimas imagens exibidas:

1. **Clareira em Duplas — selecionada pelo usuário:** time aliado em bloco 2×2 à esquerda,
   adversários em bloco 2×2 à direita, corredor de golpes no meio e cartas na
   base. Leitura clara dos lados e espaço para trajetórias.
2. **Linhas do Bosque:** quatro adversários na fileira superior, quatro aliados
   abaixo e cartas na base. Facilita comparar alvos por coluna; as posições não
   implicam regras de fileiras ou alcance ainda não definidas.
3. **Mesa de Poderes:** arena com os times em 2×2, cartas em grade na lateral.
   Preserva altura para sprites e efeitos; exige avaliar a área de toque e a
   inspeção no painel mobile.

A captura 0.3 foi inspecionada e anexada à primeira geração corrigida como
referência das criaturas; a nova primeira imagem fundamentou a consistência das
seguintes. Nenhum sprite comercial foi fornecido. As criaturas, valores e nomes
extras continuam exploratórios. Originais sem edição, cópias, hashes e revisão
estão no diretório ignorado
`artifacts/battle-concepts-simple-4v4-20261015T034739Z/`.

### Refinamento da composição selecionada

O usuário pediu câmera um pouco mais alta e corrigir a impressão de que membros
do fundo flutuavam. A revisão preserva o layout e estilo simples: mais chão
contínuo visível, posições dianteiras/traseiras no mesmo plano, sombras de contato
curtas diretamente sob os pés e barras sem encobrir o apoio. Reprojetar também
os sprites para o ângulo, sem transformar o jogo em 3D ou isometria detalhada.
As duas fileiras são composição visual; não aprovam mecânicas de posição/alcance.

Uma prancha revisada desktop/celular foi gerada a partir da imagem selecionada.
Originais sem edição adicional, cópia, hash e notas ficam em
`artifacts/battle-selected-refinement-20261016T014829Z/`. A revisão tem mais plano
de chão e sombras de apoio; a vista dos sprites ainda é majoritariamente frontal
ou de perfil e precisa de ajuste de produção. A base está escolhida; esse
refinamento específico ainda aguarda revisão. Ícones de intenção herdados são
placeholders conceituais, sem fixar o modelo de informação.

**Limites da evidência:** são imagens conceituais, sem interação, animação ou
layout responsivo implementado. As pranchas não têm as dimensões exatas dos
viewports de referência 1600×900 e 844×390; dimensões efetivas estão no manifesto.
A revisão identifica oito corpos e oito cartas nas vistas da nova série, mas
tamanho de toque, texto, grade de pixels e leitura em movimento ainda precisam
de validação na direção escolhida. Explorar celular não confirma uma nova
plataforma de lançamento.

### Refinamento atual: somente PC, de um a seis aliados

Esta prancha é o estudo anterior de ocupação máxima. D22 reabriu quantos desses
integrantes ficam ativos; aquela comparação usou 2×2 e 4×4 com HUD compacto; a direção vigente é 3×3.

O usuário suspendeu conceitos de celular. Preservar a composição 1, mas ampliar
intervalos para caudas, corpos largos e evoluções. Proposta de adaptação visual:
um aliado centralizado em sua área; quatro em 2×2 espaçado; seis em duas fileiras
de três desencontradas, sem reduzir todos a miniaturas. Os inimigos mantêm até
quatro em 2×2. Sem desenhar seis posições vazias na abertura e sem introduzir
regras de posição/alcance. Âncoras e envelopes de sprite terão validação em engine.

A nova prancha demonstra seis aliados contra quatro oponentes, com HP individual,
categorias parciais e itens externos. O alvo de briefing é 16:9 para PC; a dimensão
efetiva gerada fica no manifesto. Nomes, formas novas, HP e cartas são exploratórios.
A [direção de identidade](creature-identity.md) associa silhueta, memória,
comportamento e função; não aprova um catálogo inteiro por aparecer na imagem.

Originais, prompts, cópias e revisão estão em
`artifacts/battle-desktop-1to6-20261016T024100Z/`. Uma carta extra na primeira
geração foi retirada por edição Image Gen; ambas as versões foram preservadas.

Proposta histórica de expansores, retirada da direção de campo atual: item +1 e espécie específica +1, teto seis. Não conceder
ações ou mão adicionais automaticamente. Se o expansor for incapacitado, manter
capacidade enquanto ele integra o time, evitando uma expulsão em cadeia por dano.
Ao remover a fonte fora da batalha, resolver excesso por escolha explícita, sem
apagar indivíduos/cartas. Esses detalhes são recomendados, ainda não confirmados.

## Validação e próxima decisão

**D24 — HUD:** uma única mochila abre itens externos. Rodada usa um indicador
discreto de canto e ações ficam perto de Conjurar. Consultar a mochila não custa
ação; confirmar um uso segue seu custo e seleção de alvo. Remover os frascos
permanentes da arena e a placa grande do título. Estados de gasto planejado,
foco, mochila aberta e confirmação serão validados em interface implementada.

Na primeira fatia, verificar vida/proteção por indivíduo, intenção e alvo,
provocação/área, jogada inválida sem efeitos, custos por ações e passe de turno.
Separar mudanças em compra, nocaute e reanimação em fatias com resultado
observável; não declarar tudo concluído ao ampliar o time.

Playtest precisa responder: o jogador protege alguém por um motivo reconhecível?
Concentrar e distribuir ações têm usos? O passe de turno é uma escolha de risco
compreensível? O ciclo de compra ajuda a preparar um plano? Criaturas e golpes
mantêm presença com a mão base de seis, mãos modificadas e múltiplos alvos?

Estão confirmados ações como único recurso de execução, poderes universais/
natureza/linhagem e cartas de incapacitados permanecendo bloqueadas na mão/ciclo.
A composição 1 foi escolhida e recebeu uma revisão de câmera/apoio no chão.

Parcial confiável foi escolhido como padrão, com três níveis configuráveis sobre
o mesmo plano; início com um, teto total seis e direção ativa 3×3 orientam a rodada atual.
D35 foi ratificada na aceitação das recomendações: todos os modos disponíveis
inicialmente e mudanças comuns na rodada seguinte. D36/D37 encerram mão base,
repertório inicial, reposição e timing de reanimação; persistência do Refúgio fica
na fase própria. Alcance exato da remoção e slots de itens continuam propostas.
O formato visual aprovado continua sendo referência, sem implementação.

A prioridade atual é detalhar conservação do ciclo nas trocas, modificadores de
mão e transições de nocaute/reanimação, junto da iniciativa por velocidade e
alcances por posição confirmados em D38–D40, mantendo o
[formato visual aprovado](references/battle/00-aprovada/README.md). Três ativos é
teto fixo; três ações e efeitos de relíquias continuam hipóteses. Estudos de
dois/quatro ativos, expansores e alternativas de composição ficam no histórico.
