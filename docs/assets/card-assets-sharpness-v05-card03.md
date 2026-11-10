# V05-CARD-03 — nitidez da prévia e rejeição artística

Atualização posterior: o novo anexo de Pedro foi recebido e usado como entrada
direta em [V05-CARD-04](card-assets-reference-v05-card04.md). O bloqueio de entrada
descrito abaixo é histórico; as peças dessa fatia anterior permanecem preservadas.

Pedro rejeitou o piloto: “as imagens tao com uma resolucao muito baixa no jogo,
as molduras tao diferentes do combinado”. O objetivo desta correção é conservar
os pixels originais ao reduzir a carta e permitir ler a ilustração selecionada
na batalha. A fidelidade das molduras permanece bloqueada; esta fatia não fecha
o conceito visual implementado nem promove assets.

## Diagnóstico do fluxo completo

| Etapa | Evidência e conclusão |
|---|---|
| Originais | As seis ilustrações são PNG RGB de 1254 × 1254; molduras RGBA de 1024 × 1536. Os arquivos/metadata originais foram preservados. |
| Importação | `compress/mode=0`, `process/size_limit=0`: lossless e sem limite de tamanho. O campo lossy_quality não significa que compressão destrutiva foi usada. O teste lê PNG, textura importada e textura preparada, compara dimensões e todos os pixels RGBA do nível zero das seis artes. |
| Compressão/export | Não há redução/card atlas/variante low no caminho do novo resolvedor. O export frio de fixtures volta a importar sem sidecars locais; o resolvedor prepara as mesmas referências exatas no PCK. |
| Filtragem | `screen_host.gd` escolhe NEAREST para o mundo da batalha. O Button desenhado manualmente herdava essa filtragem, sem passar pelo helper de TextureRect. Agora somente cartas/detalhe usam LINEAR_WITH_MIPMAPS. Sprites/VFX conservam sua configuração. |
| Mipmaps | O import padrão não os gerava. O cache existente agora prepara uma pirâmide uma vez por referência exata, com Image.generate_mipmaps e ImageTexture. Não há segundo catálogo, busca latest ou mudança em PNGs/imports ignorados. Falha de leitura/decode/preparo tem diagnóstico e não produz uma textura dita pronta. |
| Tamanho na UI | Na batalha de 1280 × 720, a arte da miniatura mede aproximadamente 78 × 83 pixels CSS. Um original de 1254 pixels não pode conservar seus detalhes nesse espaço. A carta em mira agora tem um detalhe de 260 × 390 unidades lógicas; arte com 158 × 168 pixels CSS, cerca de duas vezes maior em cada eixo. |
| Resolução interna | O canvas/drawingBuffer e a leitura real da GPU coincidem com as cinco resoluções de janela testadas. Não foi confirmado framebuffer reduzido em DPR 1. Ver ressalva sobre o indicador do Godot abaixo. |

O `ViewportTexture.get_size()` do Window devolveu 1024 × 576 em uma janela
1280 × 720; **isso não era a resolução real do render**. Esse método combina
tamanho e stretch na implementação desta versão do engine. A informação foi
inicialmente interpretada incorretamente durante a investigação. A leitura
`get_image().get_size()` da GPU confirmou 1280 × 720, concordando com o
drawingBuffer do WebGL. Os dois indicadores são registrados separadamente para
não transformar metadados escalados numa falsa causa de baixa resolução.
Fontes primárias: [ViewportTexture no Godot 4.6.3](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/main/viewport.cpp#L125)
e [modo canvas_items do Window](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/main/window.cpp#L1245).

## Mudança visível e limites

O detalhe ampliado é uma projeção somente de leitura do view model da carta
em mira. Fica na faixa central livre, acima das mensagens/mão e abaixo dos
modais, com mouse_filter IGNORE e sem foco. Não cria outra carta de combate,
não executa Rules, não muda alvo nem intercepta seus cliques. Oculta durante a
execução ou sem seleção. A inspeção usa 280 × 420 em vez de 210 × 315. Texto,+custo e leitura numérica acompanham a escala do desenho. Não foi introduzida
nova animação; a transição do detalhe é imediata também com movimento reduzido.

O layout/input/quantidade da mão continuam existentes; miniaturas permanecem
pequenas em telas menores. Aumentar os PNGs não resolve esse limite físico.
Esta projeção maior não é uma alegação de reprodução do leque da referência.

A política Web existente `allow_hidpi.web=false` mantém o framebuffer em pixels
CSS, por causa do orçamento de memória no iOS. DPR 1 e densidade física Retina
não são a mesma coisa; não foi alterada essa política global nesta correção.
O diagnóstico adicional em `artifacts/card-sharpness-retina/` registra o
comportamento observado em DPR 2, sem certificar um aparelho físico.

## Molduras: comparação e bloqueio explícito

A referência de 1280 × 720 anexada por Pedro está visível no histórico: madeira,
folhas e dourado no contorno de Foli; curvas de água azuis/douradas e orbe em
Lonlon; entorno interno e ambas as placas variam com o golpe. A carta destacada
é maior e o alvo aparece junto à borda superior.

O piloto atual usa contornos mais genéricos, uma borda interna branca/dourada
espessa, placas vetoriais em cápsula, fonte sem serifa e um retângulo de seleção.
Esses elementos diferem da referência. A arte candidata de Gota serena também
não reproduz a cena com Foli da referência. Melhorar a amostragem não corrige
essas diferenças de desenho. O alvo real da fixture é Lonlon, não Foli; não foi
alterado o alvo de combate para imitar a legenda do concept.

O PNG original da referência não está no checkout, pastas compartilhadas ou
generated_images disponíveis. O PNG 1672 × 941 encontrado era um cenário de
ruínas, não o concept das cartas. Não foi repetida a transferência anteriormente
bloqueada nem gerada outra aparência a partir de suposição. Para editar as
molduras com o original como entrada, falta um anexo novamente acessível ou seu
caminho local. Nenhuma nova moldura foi fabricada nesta fatia.

Continuam 67 combinações sem arquivo de ilustração e seis com candidatos sem
aprovação. Faltam arquivos para as molduras ember/volt; as duas molduras moss/dew
existentes também não têm aceite artístico. Miniaturas reaproveitadas não
equivalem a um catálogo de retratos revisado. Runtime-lock/regras/content/saves
permanecem, e Lonlon/Bosque segue demonstração isolada não aprendível.

## Evidência verificável

- `artifacts/card-sharpness-focus/`: arquitetura, resolvedor, UI e input passaram.
- `artifacts/card-raster-evidence/`: erro de tipo Vector2/Vector2i no teste novo,
  preservado; UI/input passaram. O teste foi corrigido, sem enfraquecer assert.
- `artifacts/card-raster-pixels/`: 45 verificações reais de pixels, níveis de
  mipmap e reuso passaram. Cache de 14 componentes, 58.568.596 bytes de dados
  preparados com mips (formatos RGB/RGBA); isso não é memória residente total.
- `artifacts/card-sharpness-browser/`: 665 verificações Web passaram; primeira
  rodada ainda registrava ViewportTexture como render_size. Não usar esse campo
  antigo como prova de resolução da GPU.
- `artifacts/card-sharpness-readback/`: 675 verificações Web, cinco tamanhos ×
  texto normal/ampliado, galeria e batalha real; compara leitura GPU/canvas,
  preserva nearest no mundo, confere o detalhe, input, inspeção, pilha e toque.
  As capturas reais foram inspecionadas; título/dono/arte ampliados são legíveis
  e os alvos/comandos permanecem acessíveis. Molduras continuam divergentes.

O fechamento integral da fonte congelada deve ser consultado em
`artifacts/card-sharpness-acceptance/harness-run.json` e `run.json`; este texto
não antecipa um resultado. Testes técnicos não constituem aprovação visual.
A comparação direta antes/depois e as notas ficam junto às evidências locais;
não há exportação de screenshots para Space/Library, merge, push ou deploy.
