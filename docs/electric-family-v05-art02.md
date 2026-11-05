# V05-ART-02 — família elétrica no motor

Nisca e Niscor recebem corpos novos no catálogo e combate, dois lados, idle,
passada em quatro patas, dano, KO e origens anatômicas de ataque. Os nomes e
histórias vêm do PR #13 (`06806eb`), que sozinho mantinha os besouros.
Esta branch parte desse commit e acrescenta a arte; não houve merge.

## Referência e produção

A referência oficial `libfile_2b00aa3086e48191af8247acac969990`,
`familia-eletrica-rostos-pelos-azuis-v10.png`, foi materializada pela Library
neste executor e inspecionada: PNG RGB 1536×1024, 2.235.483 bytes, SHA-256
`8e9df8fa01d62574ea714cbddc7d912cd5b7b04b646ccdf4670762cd1d222f03`.
A identidade da Library foi aplicada localmente; não se presumiu uma cópia
de outra tarefa. O original fica íntegro em `review/approved-reference.png`.

Image Gen produziu Nisca/Niscor (`exec-631a6d5c-2c70-4afe-92ae-a85374564ee8`)
e Auravel/Zuldar (`exec-b40e0889-3930-4e13-ac1b-c1456a0c1945`), referenciados
nessa imagem. Os PNGs originais e metadados permanecem em
`review/generated-source.png` dos módulos. Nenhum recorte do cartaz é um sprite.

`tools/asset_authoring/build_electric_family.py` reproduz a normalização:
alpha ≥192 remove halo difuso, recorte por alpha, ajuste nearest, canvas RGBA
384×320, chão y=299. O lado inimigo usa a vista oposta, armazenada na direção
canônica para que a mesma malha espelhe corpo e sockets juntos. As duas vistas
não são declaradas simétricas pixel a pixel.

## Integração e compatibilidade

| Binding estável | Release proposto | Papel |
|---|---|---|
| `umbrals/volt` | `characters/electric-family@1.0.0` | `nisca-ally` |
| `umbrals/tempestral` | `characters/electric-family@1.0.0` | `niscor-ally` |

Somente esses dois pins mudam. O integrador deve combinar os índices gerados
e os dois pins com as demais frentes, sem sobrescrever bindings concorrentes.
Releases anteriores, atlas coletivos e efeitos continuam imutáveis.
`main.gd`, Rules, registro do harness e baseline não são alterados.

`creature_presentation.gd` lê dados opcionais do binding exato. Formas sem esses
dados conservam seu caminho atual. Curvas próprias articulam cabeça, patas,
orelhas e espinhos dos ouriços. Reutilizam-se somente os relógios de emissão e
contato dos ataques; não os tracks corporais de carapaça/antenas. Descargas
partem de espinhos presos ao corpo, crista ou pata, projetados pela mesma
deformação da malha. Niscor conserva pelos azuis e não tem agulhas suspensas.

Estado 6 é uma passada em quatro patas no lugar e em loop, disponível para
revisão e futuros consumidores. Não há locomoção livre nova na expedição.
Investidas usam a distância real entre slots. KO cai numa pose baixa persistente;
cancelar efeitos não restaura a pose viva. Reanimar limpa esse estado.
Movimento reduzido mostra o KO final sem animar a queda.

IDs `volt`, `tempestral`, `volt_to_tempestral`, UID, passiva, stats, poderes,
cópias e identidade do ruleset permanecem. Não há migração nova de save.

## Validação e evidências

Perfis `tools/actor_authoring/examples/volt-v1.json` e `tempestral-v1.json`
passam com `--require-complete`: idle/passada/dano distintos, seis casts com 97
amostras e reações com 61, pontos explícitos e relógios válidos. O CI de autoria
executa ambos. KO é extensão de apresentação coberta pelo teste nativo; o
schema v1 existente permanece.

`battle_motion` passou com 63 verificações na primeira rodada focada, incluindo dois
lados, sockets sobre pixels opacos, projeção de emissão, slot interativo imóvel,
KO/cancelamento/acessibilidade/reanimação e ausência de consumo de RNG.
Catálogo, consumer de assets e save também passaram na integração focada.
Pipeline verifica integridade/imutabilidade. Fechamento completo, CI e renders
finais ficam registrados no PR; resultado focado não equivale a aceitação completa.

`tools/capture_battle_performances.py --forms volt,tempestral` grava técnicas
comprometidas por cliques reais no jogo com áudio WebAudio e saída MP4.
`tools/capture_electric_states.py` exporta uma cena descartável com os atores
reais no tamanho de batalha. Esse segundo vídeo revisa apresentação; não é
uma partida. Cena de revisão e fixtures são excluídas dos exports de produção.
Evidências ficam em `artifacts/`, fora do Git.

## Pendências

Auravel alado e Zuldar bípede têm candidatas de corpo nos dois lados em
`characters/electric-adults@1.0.0`, status prototype, sem pin. Não há rig,
animações, sockets, stats ou arestas jogáveis desses adultos. O próximo trabalho
é articular asas/apoio bípede, revisar escala/ataques e então definir catálogo
e compatibilidade de saves. O desenho não escolhe automaticamente stats/poderes.
Não renomear Niscor como um dos adultos.

Revisão humana da arte/movimento e desempenho em hardware permanecem abertos.
Animações de malha não são poses redesenhadas; gates automáticos não comprovam
diversão ou aprovação estética. Produto permanece 0.3.0; a família não foi encerrada.
