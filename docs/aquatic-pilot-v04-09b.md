# V04-ART-09B — piloto aquático retomado

Base conferida por preflight: main `1523d0e`. Branch isolada
`feat/aquatic-companion-restart`; código do piloto em `63e881a`.
Os commits de nomenclatura do PR #16 foram incorporados antes da apresentação.
O ambiente anterior não foi acessado e seus arquivos não foram presumidos disponíveis.

## Resultado desta etapa

Lonlon (`dew`) e Lonaro (`mareveu`) usam corpos de lontra azul, focinho/peito
creme e marcas ciano. A esfera é uma textura separada: flutua em repouso,
parte no relógio real dos ataques aquáticos, chega à altura do alvo e retorna.
Os pontos de emissão acompanham a esfera. O ator, sua área de seleção e o
apoio no chão continuam nos slots originais. Pausa, cancelamento e movimento
reduzido conservam o contrato do combate; a apresentação não consome RNG.

O primeiro teste visual revelou que `visual=1` congelava também o ataque da
esfera; o segundo mostrou chegada alta demais por reutilizar sua âncora de
repouso. Ambos foram corrigidos e cobertos por testes. As duas tentativas
interrompidas foram preservadas, sem contá-las como aceitação completa.

## Referência e produção

A referência `libfile_2c296e23cd5c819189c30eaa74c3da82` foi materializada pelo
fluxo oficial da Library e inspecionada neste ambiente. O painel inferior
direito é a alternativa aprovada: corpo azul físico e companheiro aquático
vivo; o núcleo integrado do painel esquerdo não foi adotado.

`characters/aquatic-family@1.0.0` guarda os PNGs originais, sem edição de
pixels, com regiões aplicadas no renderer e prompts/proveniência em
`source.json`. O binding explícito está no runtime-lock. O status production
indica consumo pelo piloto, não aprovação estética da família inteira.

O atlas inclui estudos estáticos das quatro formas e de seus versos. Somente
os corpos frontais de Lonlon/Lonaro estão ativos; o lado oposto usa espelhamento.
A esfera com rosto está preservada como fonte para Lonelo, ainda sem uso no
catálogo. Os retratos de seleção, cartas e grimório mostram o corpo; a esfera
é acrescentada pelo rig de combate. A animação é procedural sobre poses
estáticas, não uma sequência de quadros redesenhados ou locomoção final.

## Compatibilidade e integração paralela

Esta etapa é cosmética. Preserva espécie `dew`, forma `mareveu`, aresta
`dew_to_mareveu`, parâmetros, cópias, UID/passiva, RNG, regras e identidade
dos saves. Não acrescenta atores, ações extras ou poderes ao companheiro.

Dono novo: `scripts/ui/aquatic_art.gd` e o módulo de assets aquáticos.
Há pequenos hooks em `battle_art.gd` e `creature_rig.gd`, mais cobertura em
`tests/battle_motion_test.gd`. Ao integrar com as outras famílias, conciliar
esses hooks com as versões novas dos arquivos; não sobrescrever seus rigs.
Mesclar somente o novo binding no runtime-lock e regenerar catálogo,
proveniência e binding_paths com `python tools/assets.py build`.
`main.gd`, regras, registro do harness, baseline e migrações não foram editados.

## O que não está concluído

Londraval e Lonelo ainda não são formas jogáveis. A continuidade exige autoria
das duas arestas e atributos, decisão explícita de compatibilidade na branch
integradora e regressões de checkpoints/replays antigos. Não basta aceitar um
novo digest: adicionar arestas a uma espécie existente muda sua progressão.
Também faltam comportamento/transformações do companheiro vivo, integração dos
versos, quadros e estados próprios de animação e aprovação visual do conjunto.
O ambiente novo e a leitura da referência estão funcionando; essas pendências
são trabalho restante, não recuperação bloqueada. Produto permanece 0.3.0.

## Evidência

Verificações focadas de catálogo, saves e movimento passaram. Na última fonte
congelada, 58 checks de movimento, 14.419 checks de regras e 86 checks de save
passaram; oito mutações foram detectadas. Integridade dos 69 releases e
imutabilidade contra a base também passaram. Ao todo 33 tarefas passaram e
um export de fixtures foi reaproveitado com hashes verificados.

O grafo completo **não foi concluído**. Depois de confirmar no histórico o fluxo
aprovado pelo usuário (checks locais focados e regressão única na candidata
integrada), o run isolado foi interrompido deliberadamente: integração Web
parcial, nove cenários Web não executados. O relatório conserva esses estados
sem convertê-los em aprovação. Houve vitória na primeira rota, captura/evolução
e formação 3x3 real; isso não substitui toda a matriz. Não há CI remoto aprovado.

Relatórios: `artifacts/harness/aquatic-pilot-focused-20261105T110451188430Z-4aece0/`,
`artifacts/harness/aquatic-grounded-contact-20261105T111135423313Z-43b108/` e
`artifacts/harness/aquatic-pilot-09b-final-20261105T111223267464Z-6aacaa/`.
Vídeos e seis capturas finais: `artifacts/aquatic-pilot-final-capture/`.

Os vídeos usam cliques reais sobre checkpoints validados do harness: três
conjurações de Jato de orvalho por forma e áudio capturado do WebAudio do jogo.
`lonlon-lonaro-piloto.mp4` normaliza o vídeo combinado para 30 fps e preserva
os originais. A captura mostra saída, contato e retorno; combate água contra
água pode sobrepor as duas esferas no impacto, junto aos VFX e rótulos existentes.
Isso continua um ponto de acabamento, não uma aprovação estética por contagem.

O piloto é entregue em branch/PR de rascunho, sem merge ou alteração de main.
O handoff privado inclui bundle Git verificável e evidências para o integrador.
