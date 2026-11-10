# V04-UX-05L — portrait e repouso canônico; acabamento ainda parcial

A revisão de Pedro preserva a floresta ultrawide de 05K e rejeita Brasa pixelado sobre pintura, Foli sentado/desperto e céu vazio no portrait. Correspondência com sprites do runtime não satisfaz o acabamento ilustrado da seção 3 da spec.

## Base, referência e limite de acesso

Preflight com fetch: main `f29752cac7d6525865091896a1466eb65a490c9c`, base local `b856b143234590db3613880521fd4dea9c1c109a`, sem atraso e árvore inicialmente limpa. A spec `libfile_680ef2a885208191806d7111558f4ff4` foi lida integralmente.

Menu oficial: `libfile_f55fcf044ed081919dbe9c40c82e07ea`, conteúdo `file_000000000b688212925d7e178f878504`, `menu-umbral-logo-integrada-lonlon-v2.png`. A leitura retornou metadados/texto e ponteiro de imagem, sem bytes locais. A preparação oficial selecionou exatamente essa identidade, mas o helper de transferência retornou `download failed`. Nenhum PNG foi instalado; não houve contorno nem nova rota após a falha. O anexo anterior continua visível na conversa, mas não é um arquivo local para overlay/prancha exata. Comparações antes/depois são rotuladas como tal.

A referência revisada e a aprovação do **Brasa inicial** não foram confirmadas. O repositório tem somente o final com três caudas. A árvore `libfile_299871807a048191ba2d69ae8bb42115` contém evoluções propostas. Contexto pessoal está indisponível; Library, o relatório histórico de comparação Pietro/Brasa/casa e a busca de PRs não forneceram uma nova aprovação verificável. Foi solicitada a identidade exata e a confirmação. Nenhuma arte nova foi gerada antes dessa confirmação; Brasa não recebeu filtro ou upscale para simular detalhe.

## Correções independentes implementadas

O portrait distribui fogo na parte superior da região cênica, Lonlon no meio e Foli/Nisca na base. Atores e apoios têm transformações independentes e escala uniforme. A imagem existente é reenquadrada pelo horizonte/área disponível; retratos mais largos usam o vale paisagem existente. Nisca foi recuado e escalado para manter os espinhos na tela. O galho de Brasa chega à lateral, sem parecer um apoio solto.

Rótulos que cabem usam duas colunas. No Web, a terceira ação fica centralizada na segunda linha; o nativo mantém quatro ações. Texto ampliado recorre à coluna quando necessário. Uma falha real de foco no retorno portrait → wide foi corrigida: o foco de Opções é capturado antes de esconder a linha. Quatro transições foram acrescentadas à suíte oficial, mantendo as verificações anteriores. A checagem real de teclado passou em 390×844 → 1600×900 → 320×568 → 800×900.

Foli agora **repousa deitada, desperta ao interagir e volta ao repouso** usando os quatro frames existentes de `characters/foli-lifecycle@1.1.0`, clip `knockout`. A última pose relaxada não tem ferimentos, lágrimas ou marcas de incapacitação. Ela é reutilizada cosmeticamente como repouso; a sequência reversível fornece a subida/abertura dos olhos e a volta. Não há alteração de HP, estado, RNG, save ou semântica de combate. Não é uma nova prancha desenhada/aprovada para o menu nem um espreguiçar dedicado.

`title_repose.gd` consome frames, pivô e altura de referência do módulo fixado, com um único relógio pertencente ao ator. A respiração é mínima e uniforme, ancorada nos pés; movimento reduzido mantém a pose de repouso. A hit shape inclui o corpo deitado e a postura desperta. As capturas reais de desktop e portrait foram abertas: olhos fechados, orelhas de folha, cauda, rosto e patas canônicas permanecem legíveis e apoiados.

`ui/living-title@2.1.0` declara a dependência de Foli e os tempos de repouso/despertar. Cena, portrait, logo, esfera, apoios, ultrawide e shader são byte a byte iguais aos de 2.0.0 (`scene-pixel-preservation.json`). Nenhum PNG foi repintado/reprocessado. As seis seleções de UI são fixadas em 2.1.0; os demais pins ficam intactos. `production` habilita a candidata técnica e `production_ready: false` conserva o limite de aprovação humana. A floresta ultrawide é preservada; os PNGs completos mudam onde Foli assume a nova pose.

## Arte e plataforma ainda pendentes

- Brasa inicial com acabamento ilustrado e referência revisada/aprovação verificáveis.
- Pata estendida e poses desenhadas específicas de empurrar/recuperar o drible de Lonlon.
- Espreguiçar dedicado de Foli e acabamento/clips finais do conjunto. Repouso e despertar por reaproveitamento já estão implementados.
- Aceite humano de identidade, composição, cadência e som; Windows/DPI/hardware, acessibilidade e controle físico.

A pose desenhada existente de Foli tem procedência e revisão técnica de integração, não aprovação artística nova. Os outros três atores conservam suas deformações procedurais atuais. A folhagem ambiental continua estática. O clipe de revisão deve mostrar essas diferenças reais, sem declarar todas as animações finalizadas.

## Evidências e ensaios

Capturas intermediárias de layout detectaram Nisca recortado e galho solto; foram corrigidos e reinspecionados. Durante a etapa apenas de layout, quatro PNGs largos eram idênticos aos de 05K (`wide-preservation.json`); essa prova histórica não é atribuída aos frames com Foli repousando. A prova atual de preservação é dos arquivos de cenário, sem mascarar a mudança intencional de pose.

O foco `title-portrait-05l-repose-focus` passou arquitetura, assets, asset-unit, título nativo (48), export Web e catálogo empacotado (5). A captura do repouso foi inspecionada em 1600×900 e 390×844. O vídeo e os ensaios posteriores identificam seus próprios hashes.

O primeiro integral `title-portrait-05l-full`, fonte `7633faee6a29caf7558a20c905e8816670951239b90a5f0f513197879015f8d4`, preservou fontes e passou a parte nativa/oito mutações. Foi interrompido durante integração Web após descobrir a sequência canônica de repouso que permitia atender Foli sem gerar arte. Não é aprovação integral nem falha de integração concluída; o relatório original foi preservado antes de editar fontes. A revisão com Foli possui o integral final descrito abaixo.

Gravações intermediárias e a falha de foco também permanecem preservadas. O primeiro gravador aguardava um snapshot que só muda por eventos; a amostragem foi corrigida com input real inofensivo, sem setters. Um erro posterior de conversão de caminho ocorreu após fechar um vídeo válido; seu arquivo foi recuperado sem repetir a captura. O clipe final deve ser da revisão com Foli repousando.

Não houve execução desta revisão em Windows/DPI. A exportação anterior de 05K em Linux não valida a nova candidata. Sem push, merge, deploy ou reativação de Actions. Produto 0.3.0.


## Fechamento técnico da revisão com repouso

`test-results/title-portrait-05l-full-03` passou integralmente: cobertura completa,
inputs verificados e fontes inalteradas. Fonte congelada
`a73fc228ed445a982c5ec46b46fba546fc272cee044408618c9a1049fe67a7cc`,
implementação `7949f66`. Os dez cenários Web somam 3.118 verificações:
integração 869, layout 1.121, navegação 160, inventário 17, combate 51,
recompensas 268, reposição 11, persistência 25, expedição 417 e título 179.
As duas rotas da expedição chegaram à vitória. A parte nativa inclui título 48,
movimento 1.012, regras 14.321, saves 559 e oito mutações detectadas.
Comportamentos foram executados novamente; somente preparação/builds com
entradas e saídas verificadas foram reaproveitados.

`title-portrait-05l-full-02` terminou com status failed e cobertura incompleta:
o coordenador encerrou após a integração passar 869 verificações, antes dos
cenários restantes. Todas as tarefas concluídas passaram e as fontes ficaram
inalteradas. Não há traceback de origem nem run.json preservado dessa saída;
a perda do pipe após retomada do ambiente é hipótese, não diagnóstico confirmado.
A rodada 03 redirecionou stdout/stderr para um arquivo persistido, sem alterar
código, orçamento de espera, ações, rotas ou asserções, e concluiu o grafo completo.
As tentativas incompletas não foram renomeadas como aprovadas.

Capturas finais reais em `title-portrait-05l-full-03/tasks/browser.title` cobrem
12 formatos, com e sem save, incluindo 16:9, 16:10, 4:3, 21:9, 32:9 e portrait.
A prancha `portrait-antes-agora.png` compara 05K/05L em 390×844, ambas sem save
com foco em Novo jogo. É antes/depois, não substituto da comparação exata com o
PNG oficial inacessível. A matriz final e as páginas do PDF foram inspecionadas;
o primeiro render do PDF revelou colisão de nomes de miniaturas, corrigida antes
da publicação. Cenário/apoios originais continuam byte a byte preservados; os
PNGs completos mudam onde Foli repousa.

O MP4 `menu-quatro-reacoes-atual.mp4` tem 34,84 s, 871 frames, H.264/yuv420p,
faststart e nenhuma faixa de áudio. Grava uma reação por ator, armazenamento
inalterado e zero erros de execução. Frames e sequência de Foli foram abertos:
repouso, levantamento, olhos abertos e volta ao repouso. O build capturado e o
integral têm todos os arquivos de runtime idênticos; diferem somente em seis
documentos, registrados em `review-dependencies.json`.

Não houve nova exportação nem execução Windows nesta revisão. A exportação
anterior de 05K não valida 05L. O resultado artístico continua **bloqueado** pelas
referências, novas poses/acabamento e gates humanos/plataforma já descritos.
Depois do ensaio congelado, somente documentação foi alterada. Sem push, merge,
deploy ou reativação de Actions; produto 0.3.0.


Entrega confirmada na Library: comparação portrait `libfile_6bbbc7065bac8191918f2d60818132b3`
(versão 0); matriz `libfile_e0d7c5a3171c8191aba2d245c97e9794`,
clipe `libfile_b60317fc56708191b611084e3f78d8d3` e relatório
`libfile_f929e579cfb08191b952377414888d2f` (versão 2 em cada um),
preservando suas identidades e histórico. Metadados locais foram persistidos;
as respostas e proveniência ficam junto às evidências ignoradas do repositório.
