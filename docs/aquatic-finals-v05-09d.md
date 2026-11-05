# V05-ART-09D — finais aquáticas funcionais

Base: main `60b4e3045ebb9188f2a1f67771a8f6bf37d714f9`, integração #31.
Escopo isolado: Londraval/Lonelo e preservação do histórico aquático. Não altera
Pietro, casa, Brasa, elétricos, grama ou workflows. Produto continua 0.3.0.

Lonaro oferece duas arestas explícitas, `mareveu_to_londraval` e
`mareveu_to_lonelo`. Ambas preservam espécie `dew`, UID, passiva e todas as
cópias físicas das cartas. Os atributos seguem a progressão numérica do
protótipo (+12 HP, +3 ataque, +1 defesa, +2 velocidade); as duas finais têm o
mesmo perfil mecânico nesta fatia. Isso não é balanceamento final aprovado.

A esfera de Londraval continua sendo água controlada. A de Lonelo usa a fonte
com rosto e uma oscilação própria, ligada à pausa/incapacitação/acessibilidade
da lontra. Não cria outro indivíduo, HP, carta, ação ou decisão de IA. Ambas
usam o relógio existente dos ataques de água para ida, contato e retorno;
multi-alvo continua sendo uma conjuração com vários destinatários.

## Compatibilidade

Catálogo 5 abre as finais aquáticas apenas para novas expedições. Grafos 0–4
são preservados sem receber novas ofertas. `combined4_manifest.gd` e
`combined_catalog4_60b4e30.json` foram capturados **antes** das alterações de
conteúdo. A migração verifica hash, projeção estrita do catálogo e estado da
origem; só adapta a identidade no checkpoint destacado. O teste reproduz
comandos reais do fixture histórico e compara o snapshot completo resultante,
inclusive RNG, planos, cartas, UID, HP e revisão. Identidade histórica com
marcador de catálogo 5 é rejeitada. Os adaptadores anteriores permanecem
exercitados pelo suite de saves e pelo gate migration-compat.

A integração acrescenta uma segunda [fixture histórica de recompensa](../tests/fixtures/combined_catalog4_main_reward_60b4e30.md),
capturada independentemente na mesma main intacta. Uma conjuração real gera
cinco escolhas ordenadas (captura, duas finais de grama e duas elétricas).
Cada escolha e o encontro seguinte são comparados integralmente com a main,
com leitura de um arquivo antigo válido e save/reload após a migração. Nenhuma
oferta foi escrita à mão; Lonaro continua sem finais no grafo 4. O manifesto
congelado também coincide com a captura independente da integração.

## Arte e limites

Referência de direção: Library `libfile_2c296e23cd5c819189c30eaa74c3da82`,
alternativa inferior direita, azul natural, sem núcleo no peito. A fonte
`characters/aquatic-family@1.0.0` permanece byte a byte intacta. Novos módulos
`umbrals/londraval@1.0.0` e `umbrals/lonelo@1.0.0` fixam AtlasTextures com
dependência explícita desse original. Status técnico `production` identifica
carregamento em runtime, **não** aprovação da arte.

São estudos estáticos existentes com deformação procedural. Versos, estados
desenhados, animações quadro a quadro, tratamento de KO próprio, aprovação
visual e hardware continuam pendentes. A esfera aparece no rig de combate;
retratos estáticos de catálogo/inspeção mostram o corpo. A companheira não
recebe uma mecânica autônoma além do vínculo de apresentação. Esta fatia não
resolve a crítica visual de Pietro e da casa.

## Evidência local

Foco congelado `artifacts/harness/aquatic-finals-frozen-20261105T162405746875Z-7831df/harness-run.json`: passou, fontes e inputs verificados, 78,382 s. Movimento 1.005 verificações; saves 464; catálogo 24; assets 560; fixtures 66; migração 5; arquitetura 140 módulos; export Web passou. A validação de assets auditou 96 releases/346 arquivos contra origin/main, sem mutações de módulos existentes.

`artifacts/aquatic-finals-runtime-20261105/capture-report.json`: duas formas, três conjurações reais/variações cada, nenhum erro de navegador, vídeo MP4 com áudio WebAudio efetivo. PNGs de idle e conjuração foram inspecionados; corpos distinguíveis, esfera separada e contatos preservados. A companheira com rosto ainda fica pequena na escala do combate; a leitura emocional não está aprovada.

A primeira tentativa de movimento teve 1.001 checks sem falhas mas foi corretamente invalidada por mudança de fontes durante execução. Não é aceite; a execução congelada acima inclui as quatro verificações adicionais da companheira (idle, pausa, KO e redução de movimento).

GitHub Actions permanece desativado.
A regressão integral do candidato combinado fica com a integração, conforme
preferência por foco por feature e uma única regressão conjunta.

## Evidência da integração

O foco de saves da integração passou com 498 asserções, incluindo recompensa
histórica pendente, cinco escolhas, próximo encontro, idempotência e rejeição
atômica do grafo falsificado. A primeira montagem de arquivo no teste misturou
identidades do envelope/snapshot; a tentativa falha foi preservada e corrigida
para representar o envelope histórico válido. Não houve alteração de produção
nessa correção. O movimento dessa tentativa não vale como aceite, pois as
fontes foram corrigidas antes do término da tarefa.

O relatório integral da revisão congelada fica em
`artifacts/aquatic-finals-integration-full-proof.json`, com referência à pasta
imutável da execução, hashes, logs e vídeo. Seu status e o SHA identificam o
aceite efetivo; os focos acima não substituem esse gate. A apresentação da
esfera não implementa uma entidade autônoma nem uma habilidade de ataque duplo.
