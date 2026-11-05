# V05-CNT-02B — Folivel jogável e dorsais da linhagem

Folivel, alternativa aprovada na v13, entra por `verdalio_to_folivel`,
partindo de Folife. Preserva espécie `moss`, UID/passiva e as instâncias de
cartas. Foslash continua uma alternativa explícita da mesma origem.
Os dois finais têm os mesmos números provisórios 72/14/6/12 e o mesmo
incremento de perfil de poder; esta fatia não inventa diferenciação de
balanceamento ou novas técnicas definitivas.

## Compatibilidade explícita

A identidade atual é `expedition-rules-4` /
`adb2e79ba0b52d2b9fe9e2fa9299f2c3e425017199f6f8086263cef2bb02d418`,
catálogo 2. O manifesto `07942959…8442` anterior está congelado como fonte
histórica e conserva catálogo 0 ou 1 em seus saves. Não há opt-in automático
para 2. A comparação de compatibilidade retira somente os sufixos auditados,
de trás para frente, até a revisão da fonte. Rejeita catálogo 2 forjado sob
uma identidade anterior, inclusive quando nenhum corpo novo aparece no save.

Fixtures reais anteriores à adição preservam 61 comandos de catálogo 1
(Foslash/boss) e 59 de catálogo 0 após migração. Os testes comparam snapshots,
RNG, planos, cartas e ofertas completos, além de casos forjados e bytes de
armazenamento protegido. A rodada pura passou 252 checks de save e 56 de
expedição; o gerador validou reward→Folivel→boss por APIs de produção.

## Arte e apresentação

- `characters/folivel-pilot@1.0.0`: retrato frontal da v13 e um dorsal novo,
  inspecionado como quatro patas, com anatomia/grounding próprios por vista.
- `characters/folivel-lifecycle@1.0.0`: oito poses frontais de caminhada,
  quatro de KO; quatro dorsais de caminhada e quatro de KO reversível.
- Foli/Folife recebem versões 1.1.0 de piloto/lifecycle. As versões 1.0.0
  e os pixels/tracks frontais são preservados. Dorsais têm quatro poses de
  caminhada/KO e não emprestam clips nem anatomia frontais.
- Atores do lado oposto selecionam o dorsal quando há fonte própria. O
  facing usa espelhamento dessa fonte dorsal, explicitamente distinto de
  chamar o frontal espelhado de verso. Os alvos permanecem nos mesmos slots.
- Folivel usa as três apresentações de folhas-lâminas no mesmo poder
  existente. Não há novos IDs de poderes, cartas adicionais ou RNG visual
  consumindo a sequência de gameplay.

Originais PNG/caBX, hashes e normalizações são preservados nos módulos.
Derivados usam somente recortes de grade e translações inteiras, sem reescala,
redesenho ou limpeza que destrua o original. Fontes rejeitadas com quinta
pata e a tentativa incompatível de complementar a posterior ficam fora dos
pins. O ciclo dorsal de Folivel permanece limitado: a posterior próxima
fica quase sempre apoiada nas quatro poses; não é marcha completa aprovada.

A calibração de Folivel usa altura frontal limitada pela largura do ator:
no slot de 230 px, frontal≈109,74 px e dorsal≈110 px. Outros tamanhos/depths
podem divergir. A altura dorsal de referência 450 é equivalente por largura,
não a altura literal de 416 da primeira pose; isso preserva uma aproximação
de volume, ainda sujeita à revisão na arena. Folife dorsal varia colar,
chevron e postura. Clips usam corte de silhueta, com pop perceptível possível.

## Fechamento e limites

A matriz nativa `artifacts/grass-rear-native-matrix-v2/` recebeu GO técnico
independente para as doze combinações (três formas × duas vistas × facing).
Foram preservados 240 PNGs reais; o MP4 contém 221 quadros em 12,04 s. O maior
intervalo de captura foi 462 ms: não é uma aprovação de cadência. O preview
controla somente apresentação. Já o lifecycle na cena real passou 16/0 em
`artifacts/folivel-native-game-lifecycle-v1/`, HP 72→0→26, mesmo UID 1.

A escolha por mouse X11 teve tentativas falhadas preservadas: press chegou,
release apareceu como unhandled, e o botão permaneceu pressionado. O probe
sem gravação também reproduziu. Estabelecer foco X11 uma vez antes do primeiro
clique permitiu press/up/pressed, evolução e três casts (25/0), sem retry por
ação nem mudança de UI. A causa interna exata da captura perdida é inferida;
não foi atribuída a gameplay nem corrigida com patch de interface. O probe
intermediário com handle nativo errado foi uma falha do driver, preservada.
Vídeo da execução focada e detalhes ficam no PR e nos artifacts.

Evidência nativa, revisão independente e aceitação integral são registradas
no PR para o commit congelado. O caminho exigido é `tools/iterate.py --video`,
com checks completos, exports, input real e matriz de resoluções, usando o
piloto anterior como baseline. Falhas ficam preservadas; testes focados não
substituem esse fechamento. A observabilidade mínima de versões do #23
permanece; o patch amplo de seleção de browser não foi aplicado.

Verso de Foslash continua bloqueado na geração, sem retry. Casts de corpo
usam meshes próprios; as quatro poses novas de Foslash continuam em staging,
sem integração. A lâmina pintada de Foslash permanece durante o projétil.
Aprovação estética, performance/fluidez e marcha quadrúpede dorsal completa
continuam abertas. Draft separado sobre #23, sem merge ou aumento da versão
0.3.0 e sem alegação de família pronta para produção.
