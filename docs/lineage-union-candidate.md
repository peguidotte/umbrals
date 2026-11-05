# Candidata local: grama final e elétrica sobre 4df4809

Fatia de integração V05-CNT-02, produto 0.3.0. Combina a grama revisada de
#23 c7f9ec18 e #24 a9dc51e com a candidata elétrica/casa/foco 4df4809.
O #25 cb713b2 inclui outra base de casa/Brasa; aproveitamos sua instrumentação
mínima de falha de Session, preservando a base 4df4809 e os pins elétricos e
Pietro 2.0.0. Não importa a base #15, não promove main e não publica PR.

## Catálogos históricos e decisão de compatibilidade

A grama introduz rules4 e catálogos por expedição. A integração mantém esse
contrato e registra a elétrica independente, em vez de assumir que um número
maior implica todas as extensões anteriores. As revisões são IDs de grafos:

| Revisão | Formas adicionais disponíveis |
|---|---|
| 0 | Nenhuma: catálogo histórico anterior às finais |
| 1 | Foslash |
| 2 | Foslash e Folivel |
| 3 | Auravel e Zuldar, histórico elétrico independente |
| 4 | Ambas as extensões, padrão das novas expedições |

A identidade de regras é expedition-rules-4; o conteúdo combinado tem seu
próprio digest. Saves de rules2/rules3 anteriores às extensões mantêm grafo0,
com a revisão de Nascente preservada conforme sua origem. Saves da elétrica
90f86d29…65b1e4 migram ao grafo3, preservando suas adultas, ofertas diferidas,
RNG, cartas, UID e passiva. Catálogos07942959…78442 e adb2e79b…2d418 mantêm
0/1 e 0/1/2 respectivamente. Somente começar uma nova expedição seleciona4.
Assim, um save pré-adultas não recebe evoluções futuras durante o percurso.
Isso é o contrato explícito rules4 da grama; a regressão de adultas atuais usa
um fixture privado declarado atual, sem fingir que ele é um save histórico.

Os manifestos elétrico e grama2 foram congelados executando Identity.manifest
nas origens 4df4809 e a9dc51e antes do merge, e seus hashes conferem com as
identidades revisadas. Comparadores conservadores continuam verificando cada
campo antigo. As formas elétricas recebem somente a marca catalog_revision3;
a projeção auditada remove exclusivamente essa marca ao comparar o manifesto
elétrico anterior. Não muda stats, custos, natureza ou balanceamento.

O grafo atual filtra formas/arestas por revisão explícita e mantém as ofertas
elétricas diferidas depois das ofertas históricas de todos os indivíduos.
Revisões malformadas ou incompatíveis com a identidade original são rejeitadas
antes de normalizar; inteiros JSON equivalentes são aceitos sem elevar o grafo.

## Apresentação compartilhada

BattleArt/Motion aceitam vistas nomeadas, mantendo o chamador elétrico anterior.
Elétrica conserva texturas laterais e seu cache de malha/KO; grama recebe as
vistas dorsais e lifecycles próprios, altura e sockets de folhas. Troca de UID,
restauração e recuperação preservam o sincronismo único de 4df4809. Owl, Spore
e Stag continuam usando tracks legados, sem herdar as novas anatomias.

A instrumentação de cb713b2 guarda o primeiro estado de falha antes da captura
e registra condição/prazo. Não altera deadline, seleção de browser, retry ou
caminho bem sucedido. A causa dos quatro timeouts locais de #25 permanece
aberta; o CI verde da origem não é aceitação desta composição.

## Evidência e limites

O movimento combinado passou829 checks; regras14.346, assets555, casa79,
foco87, história26 e fluxo437 passaram no foco inicial. Após conciliar saves,
433 asserts de save e5 cenários de migração passaram. A tentativa inicial de
importação invalidada por mudança de fonte e as falhas intermediárias foram
preservadas em artifacts/harness/grass-electric-*. A regressão inclui o erro
observado de alternância de ordem entre chamadas do adaptador, agora sem
mutação da lista de extensões. Baseline de arquitetura não foi alterada.

Aceitação completa, capturas e resultados exatos são registrados no relatório
artifacts/lineage-union-full-proof.json após o congelamento. Até esse relatório
confirmar cobertura completa, os focos não representam aceitação integral.
O novo adaptador de união deve receber revisão independente antes de promoção.

Família permanece parcial: Foslash usa front no rear; lâmina pintada e casts
corporais em staging; Folivel dorsal com marcha limitada; estética, cadência e
hardware abertos. Recuperação elétrica ainda sobrepõe corpos; números são
provisórios. Pietro45d56a1 permanece fora por origem indisponível neste executor.
Nenhuma geração bloqueada ou publicação de PR negada foi repetida.
