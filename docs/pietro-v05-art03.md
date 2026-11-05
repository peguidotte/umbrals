# V05-ART-03 — apoios alternados de Pietro, candidato

Esta fatia parte de `d6fea29`, em branch independente. O PR #17 continua
congelado em `1fda638`. As duas revisões anteriores terminaram com sete jobs
aprovados, nas execuções `41960266212` e `41967954911`, respectivamente.
Esses resultados não certificam esta nova fatia.

## Comportamento e autoria

A escada usa duas pernas articuladas sobre os pixels originais do repouso de
`characters/pietro-home@2.0.0`. Nenhum PNG é alterado ou duplicado. O módulo
`characters/pietro-stair-contact@1.0.0` contém marcos anatômicos, regiões de
malha e coreografia, depende explicitamente dos módulos anteriores e recebe um
pin próprio. Seu AtlasTexture referencia a fonte imutável; os índices são
regenerados preservando todos os demais bindings.

Uma perna permanece apoiada enquanto a outra passa ao próximo apoio. Depois do
primeiro passo, cada pé avança dois degraus, alternadamente. A trajetória da sola
tem afastamento vertical e uma fase de apoio duplo antes da troca. O quadril
acompanha os apoios sem receber a elevação do pé em trânsito e continua a
transferir peso durante o apoio duplo, evitando parar após cada contato. Os joelhos
usam duas articulações e as botas mantêm sua orientação no contato.

O progresso real da escada dirige a apresentação: pausa congela o estado e a
inversão refaz as trajetórias interiores. Próximo aos patamares os pés recolhem
para os pivôs do repouso da direção escolhida. A mudança de orientação durante
uma inversão continua imediata. Movimento reduzido usa as poses estáticas
anteriores, sem flexão cíclica, e mantém a travessia.

`pietro_stair_gait.gd` calcula a apresentação dos apoios;
`pietro_stair_rig.gd` aplica a malha; `pietro_pose_view.gd` seleciona rig ou pose
estática e `refuge_canvas.gd` desenha e publica diagnóstico cosmético de leitura.
O navegador não recebe setters. Geometria, velocidade, câmera, saves, Rules,
sessões e conteúdo mecânico permanecem inalterados.

## Revisão visual e limites

**Continua candidato, sem aceite estético e sem merge.** A primeira malha
compartilhada puxava parte da mão e distorcia a calça; foi rejeitada. A divisão
das pernas removeu essa ligação. O tronco usa o complemento exato das regiões
das pernas, evitando recortar pixels do desenho original. Uma tentativa de
interpolar o lado de flexão encurtou o triângulo das articulações; o teste de
alcance detectou a falha e a interpolação foi removida.

Alternância e permanência dos apoios podem ser medidas, mas a textura de repouso
não contém as superfícies escondidas pelas mãos e pela roupa. Ainda há rigidez
na junção quadril/coxa, pouca participação de braços/tronco e mudança imediata
de orientação na inversão. Uma arte própria com camadas de membros e poses de
esforço é o próximo trabalho visual, caso este candidato não passe pela revisão.

O despertar conserva os seis desenhos próprios e os apoios finais calibrados
da fatia anterior. Deve ser revisto no novo MP4: as mudanças de orientação entre
desenhos e a passagem da borda da cama ao chão ainda precisam de avaliação
humana. Não substituir essa avaliação pelos testes.

## Evidência e contrato de validação

O handoff acompanha testes focados da casa, catálogo, integridade/imutabilidade
e arquitetura, além de export Web e entradas reais no navegador com vídeo MP4.
Os novos casos verificam apoio fixo, alternância, ausência de fase aérea dupla,
solas nos polígonos reais, alcance das articulações, inversão e chegada exata ao
desenho de repouso. A varredura de câmera usa posição e progresso coerentes;
o caso anterior combinava a posição de um patamar com frames de outro ponto.

O observador Web lê o snapshot cosmético para medir a alternância e o maior
deslocamento entre observações consecutivas do mesmo apoio. São necessários
ao menos vinte pares de apoio observado e dez trocas alternadas, com deriva
inferior a 0,01 pixel de mundo. A frequência do snapshot limita a amostragem;
isso não mede a taxa de quadros da animação nem a qualidade visual.

Tentativas falhas e capturas internas permanecem em `artifacts/`, sem entrar
no produto. A entrega registra os caminhos e hashes exatos, contagens reais,
revisão do vídeo e limites. Não há nova rodada integral ou rerun da CI anterior.
