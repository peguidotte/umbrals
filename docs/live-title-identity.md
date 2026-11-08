# V04-UX-05K — identidade canônica e floresta ultrawide

Pedido de Pedro: os iniciais precisam corresponder aos designs reais; a largura extra deve continuar a floresta com árvores nas laterais.

Fontes consultadas: lebre-linhagem, elétrica aprovada (base), prancha aquática (escopo inferior direito), bodies aquáticos e sprites canônicos, atlas de Brasa. A prancha de fogo é somente final com três caudas, não referência de inicial.

Implementação candidata: o título consulta os mesmos bindings BattleArt que o jogo. Texturas não são redesenhadas; a malha de apresentação só recebe poses cosméticas de amplitude limitada. Foli mantém orelhas/cauda-folha, coloração e perfil originais; Nisca mantém cabeça, patas, espinhos e acentos azuis; Lonlon mantém faixa ciano, ventre e bigodes; Brasa usa o atlas real atual. Nenhuma regra, catálogo, save ou balanceamento é editado.

Limite preciso: falta a prancha revisada independente de Brasa inicial. Também não há folhas desenhadas específicas do menu para Foli dormindo ou Lonlon driblando. As poses da candidata são de apresentação sobre os pixels existentes e não se apresentam como novas animações aprovadas.

Ultrawide: nova extensão de árvores, troncos, raízes e samambaias, sem clareiras laterais. Centro 16:9 permanece byte a byte o mesmo clean plate da candidata anterior; em ultrawide a paisagem deriva desse centro, com cobertura uniforme e recorte em vez de estiramento. Atores têm palco central e escala uniforme independentes da largura.

Aceite humano, Windows/DPI e comparação por overlay com bytes da referência anexada continuam abertos. Evidências automáticas devem identificar seu escopo e source hash. Tentativas anteriores falhas/interrompidas permanecem preservadas.


Busca complementar no Space: localizados estudos de Brasa (árvore v2 libfile_299871807a048191ba2d69ae8bb42115; apagada v3 libfile_c12edef408ac819198304f1c1462a57b; exploração libfile_079012570d088191bfe98941f6f5f0ef). O helper oficial falhou antes de preparar downloads em tools/list (network), e a recuperação de contexto pessoal ficou indisponível. Não foram tratados como imagens inspecionadas ou aprovações recuperadas. A candidata conserva o sprite canônico já legível; não inventa um novo inicial.


## Contrato de arte e fontes

| Ator | Fonte efetiva | Preservação |
|---|---|---|
| Brasa / `ember` | `characters/battle-creatures@1.0.0`, região 40,54,371,364 | Sprite canônico atual; não há confirmação de uma nova prancha inicial legível nesta execução. |
| Foli / `moss` | `characters/foli-pilot@1.1.0`, `foli.png` | Orelhas e cauda-folha, rosto, cores e proporções originais. |
| Lonlon / `dew` | `characters/aquatic-family@1.0.0`, região 40,175,250,230 | Bigodes, ventre, corpo compacto e faixa ciano; esfera separada. |
| Nisca / `volt` | `characters/electric-family@2.1.0`, `nisca-enemy.png` | Base azul/violeta, focinho, patas, espinhos e acentos elétricos; espelhamento nativo para olhar ao centro. |

`ui/living-title@2.0.0` mantém cena, retrato, logo, apoios, esfera e shader anteriores sem editar seus bytes. Substitui a paisagem ultrawide e retira os quatro atlas de corpos inventados dos bindings ativos. Dependências canônicas são explícitas; releases antigos permanecem intactos. O original gerado da floresta fica em `review/ultrawide-original.png`, com metadados preservados. Status de produção no catálogo permite a candidata em runtime e não constitui aprovação artística.

`title_actor.gd` consulta BattleArt e os pivôs reais, conserva escala uniforme e controla somente a pose decorativa. O rig compartilhado recebe um override de apresentação, com esfera externa pertencente ao título; `reset()` restaura a renderização padrão do combate. Nenhuma textura de personagem é recriada, recortada para distribuição ou repintada. A matriz em modo congelado não reconstrói malhas a cada frame.

## Evidência e limites de aceite

- `test-results/title-identity-initial`: tentativa inválida por alterações de fonte durante preparação; não é aprovação.
- `test-results/title-identity-01`: interrompida para corrigir a camada da esfera.
- `test-results/title-identity-native-02`: título 48 e movimento 1012 passaram; conjunto falhou no tamanho do rig (353/350). O limite não foi aumentado.
- `test-results/title-identity-03`: tentativa intermediária interrompida após o guard ainda apontar 351/350; interface foi reduzida mantendo o limite.
- `test-results/title-identity-04`: foco aprovado, título nativo 48 e Web 174, com 12 formatos salvos/vazios, toque, Opções, save/Continuar e igualdade das capturas de movimento reduzido. Fonte anterior ao ajuste final da altura aquática em 32:9 e à remoção de atualizações de malha congelada.
- `test-results/title-identity-layouts`: sete capturas reais; 28 verificações suplementares confirmaram fonte canônica e proporção uniforme dos corpos. A inspeção detectou a âncora aquática alta em 32:9, corrigida em seguida.
- `test-results/title-identity-final-web`: export Web e catálogo empacotado aprovados da implementação final; exportação não é aprovação visual.
- `test-results/title-identity-final-layouts`: capturas complementares da revisão final, em 1600×900, 1440×900, 2560×1080, 5120×1440, 800×600, 390×844 e 320×568; estado público somente leitura preservado junto a cada PNG.
- `test-results/title-identity-full`: primeira tentativa integral, fontes inalteradas. Toda a parte nativa e as oito mutações passaram. A integração Web falhou após 307 verificações ao aguardar a fila animada por 60 s; captura mostra efeito 18 de 21, e os últimos 12 s de vídeo avançam do efeito 6 ao 18. A tentativa foi interrompida em layout para ajustar somente a sincronização do harness. Não é aceitação integral.
- `tools/browser/session.py`: espera por `!busy` ampliada de 60 para 120 s, com duração medida por fila. Nenhuma ação, asserção, rota, resultado esperado ou velocidade do jogo foi removida/alterada. A falha e os frames do diagnóstico permanecem preservados.
- `test-results/title-identity-full-02`: nova tentativa integral com fontes congeladas após o ajuste de sincronização; usar seu relatório real para o resultado.

Pranchas comparativas e vídeo MP4 para celular ficam em `test-results/title-identity-delivery/`. A comparação de identidade mostra fonte real do jogo, candidata anterior e recorte da execução Web. A comparação de floresta usa capturas reais em 5120×1440, na mesma proporção e estado sem save. Não transforma diferença de pixels em nota de beleza.

Pendências explícitas: confirmar/materializar a referência revisada de Brasa inicial; poses desenhadas específicas de repouso/drible; aprovação humana da composição/cadência; Windows/DPI, controle físico, escuta e hardware. A folhagem ambiental continua estática. O acesso aos bytes do menu aprovado para overlay normalizado continua bloqueado; a imagem anexada foi vista na conversa. Produto permanece 0.3.0. Sem push, merge, deploy ou reativação de Actions.
