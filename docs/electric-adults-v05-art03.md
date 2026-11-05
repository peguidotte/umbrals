# V05-ART-03 — Auravel e Zuldar jogáveis

Continuação em draft sobre V05-ART-02 / PR #19. A escolha após Niscor oferece
Auravel alado ou Zuldar bípede. Escolher uma forma preserva UID, passiva,
posição, técnicas conhecidas, instâncias físicas de cartas e proporção de HP.
A forma escolhida entra no próximo encontro e pode ser retomada pelo save.
Nisca/Niscor mantêm IDs `volt`/`tempestral` e a aresta original.

## Arte e movimento candidatos

`characters/electric-adults@2.0.0` promove as duas vistas dos corpos candidatos
1.0.0 para consumidores com rigs, idle, passada, dano, carga, seis casts,
sockets e poses de KO desenhadas com olhos fechados. Os originais gerados
continuam íntegros em `review/`, junto da referência oficial já materializada
no executor (SHA-256 `8e9df8fa01d62574ea714cbddc7d912cd5b7b04b646ccdf4670762cd1d222f03`).
Não foi necessário gerar novamente as imagens após a interrupção do executor.

Auravel articula as duas asas nos ombros e mantém quatro contatos de apoio.
Zuldar articula braços e duas pernas, com dois contatos. Espinhos azuis ficam
presos ao dorso. A recuperação usa a transição de 0,8s existente. O desenho de
KO do Auravel ainda conserva as asas levantadas; dobrá-las completamente e
refinar as transições são itens de revisão artística, não trabalho concluído.
Animações usam malhas e transição entre poses, sem alegação de frames finais
redesenhados. A passada de revisão não adiciona locomoção livre à expedição.

Auravel pode exceder a largura padrão do retrato para manter o corpo adulto
legível abaixo das asas. A altura, chão e slot permanecem fixos; a margem de
salto passa a usar a altura declarada da forma. As capturas devem verificar
os dois lados no tamanho real e o encontro integrado, além dos testes numéricos.

A release `characters/electric-family@2.1.0` preserva a 2.0.0 e move somente a
origem secundária do Niscor de `[0.51,0.12]` para `[0.58,0.22]`, sobre um espinho
preso e opaco nas duas vistas. A checagem ampliada encontrou o ponto anterior
fora do corpo. Novos pins exatos: Nisca/Niscor em 2.1.0; Auravel/Zuldar em 2.0.0.
Índices gerados devem ser reconciliados pelo integrador com outros PRs.

A transformação comum da pose é calculada uma vez e aplicada aos vértices.
A projeção direta dos sockets permanece como referência; o teste compara os
225 vértices da grade mais os contatos de apoio em quatro formas, dois lados, idle/passada/dano e três casts,
incluindo salto e rotação. Não se usa o experimento rejeitado de buffers dinâmicos.

## Conteúdo e compatibilidade explícita

Nomes, bifurcação e direção corporal foram aprovados por Pedro. Os atributos
abaixo são **defaults de protótipo por delegação**, sujeitos a balanceamento:

| Forma | HP | Ataque | Defesa | Velocidade | Naturezas | Circuito Vivo |
|---|---:|---:|---:|---:|---|---:|
| Auravel | 56 | 16 | 2 | 25 | Raio / Maré | 8 |
| Zuldar | 64 | 19 | 4 | 17 | Raio | 8 |

Ambos conservam resistência elétrica de 25% e o conjunto de técnicas da
linhagem; evoluir não concede cartas de assinatura automaticamente. Perfis de
incrementos ficam explícitos em `content/species/volt/species.tres`. Descrição
de Julgamento passa a referir o portador para não chamar as adultas de Niscor.

Arestas explícitas `tempestral_to_auravel` e `tempestral_to_zuldar` declaram
`deferred: true`: suas ofertas aparecem depois de todas as ofertas históricas
de todos os indivíduos. A captura continua primeiro e consome a mesma escolha
de RNG. Isso preserva índices válidos dos comandos antigos, mesmo quando outro
membro do time ainda pode evoluir. Ofertas antigas já pendentes ficam intactas.

Decisão de compatibilidade: manter `expedition-rules-3`, com novo digest de
conteúdo e migração auditada da identidade pré-adultas `7df20eb4…`. Não há
mudança no resultado dos comandos válidos anteriores nem nos dados antigos;
a escolha de uma nova forma é um comando novo deliberado. O comparador
`lineage_extension` exige prefixos idênticos de formas/arestas, definições
anteriores intactas e novas arestas adiadas apontando somente para novas formas.
Também preserva os prefixos de naturezas secundárias e valores de traço.
O comparador aditivo original continua estrito. Identidades desconhecidas,
reordenações, alterações de stats antigos e estados históricos forjados são rejeitados.

A migração rules-3 preserva `event_revision=1` e uma Nascente pendente; somente
rules-2 recebe revisão 0. Schema/envelope permanecem 2. O fixture congelado
`electric_rules3_before_adults.json` foi produzido antes de alterar o catálogo.
Ele testa uma equipe Niscor/Brasa/Musgo, recompensas antigas, escolha por índice,
próximo encontro e snapshot completo normalizado, incluindo RNG e planos.
Testes também escolhem ambas as novas arestas e retomam cada save adulto.

Revisão adicional de HP corrigiu uma expectativa de teste que usava `roundi`,
enquanto a regra histórica usa `ceili` para preservar a proporção positiva e
mantém zero no KO. O checkpoint cheio ocultava a diferença. Ambas as adultas
agora passam pela API real com HP 48, 1, 19, 47 e 0, preservando cartas e
identidade e retomando o snapshot de cada resultado. A suíte passou com 167
assertions em `artifacts/harness/electric-adults-injured-ko-20261105T070722171872Z-79769d/`.
Uma mutação temporária de `ceili` para `roundi` falhou nos quatro casos feridos
que distinguem os arredondamentos; a regra foi restaurada sem alteração.
Essa correção amplia a cobertura e não muda atributos ou balanceamento.

## Evidência e limites

Depois da recuperação, fixtures e saves passaram em
`artifacts/harness/electric-adults-recovered-20261105T045033333641Z-896e57/`;
saves incluem 113 assertions. Projeção e arquitetura passaram em
`artifacts/harness/electric-affine-projection-20261105T045811056213Z-76bb83/`.
Autoria valida os quatro perfis com as mesmas origens por forma do runtime;
33 testes Python incluem precedência e rejeição de override incompleto.

`capture_native_electric_states.py` e `capture_electric_states.py` aceitam
`--adults --form auravel|zuldar` para revisar um par de vistas por gravação.
Telemetria mede frames reais; o FPS nominal do MP4 não substitui esse dado.
A primeira captura simultânea de quatro adultos caiu para 14–24 FPS em alguns
estados neste Mesa/CPU, e é preservada como insuficiente para avaliar cadência.
Capturas por forma não são prova de desempenho de uma batalha 3×3.

`capture_electric_progression.py` usa cliques reais nas duas recompensas, grava
a forma no encontro seguinte e seis apresentações por adulta com poderes
realmente pertencentes ao indivíduo. O boot de fixture tem checkpoint/replay
validado e telemetria de frames desenhados, é somente de teste e não entra no
export de produção. Receptores de alta resistência permitem observar três
rodadas; isso não certifica balanceamento. Não há setter no bridge de produção.

Fechamento integral, CI do HEAD e capturas finais ficam no PR separado desta
fatia. Revisão humana de arte/animação, desempenho em hardware e balanceamento
continuam abertos. Não houve merge; versão do produto permanece 0.3.0.

Revisão adicional de apoio: interpolar a grade original deixava o pé visível
variar até 3,3px, embora `project(uv)` passasse no teste de ponto fixo. Os contatos
agora são vértices reais da malha triangulada. O gate lê os vértices renderizados
e verifica apoio, além da equivalência de projeção. Essa correção é de apresentação
e não muda a identidade de gameplay. A captura pode usar `--resolution 1280x720`;
FFmpeg limita encoder/filtros a uma thread e Mesa pode usar quatro, conforme a
cota de CPU. Relatórios anteriores lentos permanecem preservados.

A captura nativa corrigida espera o primeiro frame visível e o primeiro frame
codificado pelo gravador antes de armar o relógio do ciclo. O jogo confirma esse
início; a gravação segue até depois do ciclo inteiro, sem corte fixo em 26s.
Readbacks de PNG durante movimento ficam desligados; as imagens são extraídas
do próprio MP4. Proveniência registra duração, início do ciclo e intervalos
pretos. O vídeo nativo antigo, com início preto e ciclo cortado, foi excluído
como prova. A dissolução de recuperação ainda sobrepõe silhuetas; uma alternativa
isolada pode ser comparada antes de mudar os consumidores preservados neste PR.
