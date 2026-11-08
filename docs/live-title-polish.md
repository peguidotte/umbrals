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

O primeiro integral `title-portrait-05l-full`, fonte `7633faee6a29caf7558a20c905e8816670951239b90a5f0f513197879015f8d4`, preservou fontes e passou a parte nativa/oito mutações. Foi interrompido durante integração Web após descobrir a sequência canônica de repouso que permitia atender Foli sem gerar arte. Não é aprovação integral nem falha de integração concluída; o relatório original foi preservado antes de editar fontes. A nova revisão deve executar seu integral próprio.

Gravações intermediárias e a falha de foco também permanecem preservadas. O primeiro gravador aguardava um snapshot que só muda por eventos; a amostragem foi corrigida com input real inofensivo, sem setters. Um erro posterior de conversão de caminho ocorreu após fechar um vídeo válido; seu arquivo foi recuperado sem repetir a captura. O clipe final deve ser da revisão com Foli repousando.

Não houve execução desta revisão em Windows/DPI. A exportação anterior de 05K em Linux não valida a nova candidata. Sem push, merge, deploy ou reativação de Actions. Produto 0.3.0.
