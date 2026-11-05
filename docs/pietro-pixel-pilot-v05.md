# V05-ART-08 — Pietro pixelado: comparação parada e caminhada curta

Piloto isolado, atualizado sobre a main `1da3ad1`, separado das animações anteriores. Pedro aprovou
a nova cena de direção artística e o Pietro isolado. A implementação e sua
caminhada continuam candidatas: a aprovação da referência não aprova o resultado.

## Escopo observável

O estudo abre com Pietro, Brasa e a sala no mesmo enquadramento. **Comparar
parado** usa o PNG isolado aprovado, sem alteração de pixels. **Conceito aprovado**
mostra a cena original para comparação. **Caminhada curta** recolhe os pés,
percorre três ciclos e volta à pose e à posição da comparação parada.

O arquivo de Pietro é RGBA de 1254×1254, SHA-256
`cc20c83377533cc93c79e141f6490bcc8e056f36a05013f28b66111956c0bbfa`.
Foi materializado pelo fluxo oficial da Library neste executor; bytes, alfa e
pixels foram conferidos antes da implementação. O rig amostra esse mesmo PNG.
Polígonos de recorte, articulações e pivôs ficam em JSON separado. Não há nova
folha de personagem gerada por IA. O tronco inclina levemente; os braços se
opõem à passada e a mochila acompanha com atraso. As pernas são articuladas e
as botas transladam sem deformação ou rotação. O PNG aprovado permanece intacto.

A base da sala recebeu uma única edição dirigida para remover o Pietro que
estava fundido à imagem. Brasa permanece uma referência estática dentro dessa
base, sem animação ou comportamento novo. A saída tem 1585×992; a referência
original tem 1586×992. Portanto não se afirma que Brasa ou o cenário tenham
permanecido idênticos pixel a pixel. O rodapé conceitual é recortado pelo renderer.

A altura de Pietro, os pontos de apoio e o quadro são calibrados à cena aprovada.
O estudo tem resolução lógica 1600×1000, incluindo controles abaixo da área de
1586×880 da cena. Filtro nearest, escala do ator 0,65 e pivô [620,1130]. A marcha
é dirigida pela distância, com apoio plantado durante cada meia passada e
levantamento separado da outra perna. Cada bota conserva sua faixa na projeção
de três quartos; o avanço relativo das pernas se alterna. O ciclo fecha. Somente a
vista de três quartos para a direita está incluída.

## Reprodução

```bash
source tools/environment.sh
godot --path . tools/studies/pietro_pixel/study.tscn
python tools/studies/pietro_pixel/check_source.py
godot --headless --path . --script tools/studies/pietro_pixel/test_rig.gd
python tools/studies/pietro_pixel/build_preview.py --output artifacts/pixel-study
python tools/studies/pietro_pixel/review.py --build-dir artifacts/pixel-study/build --output artifacts/pixel-study-review
```

Os arquivos do estudo ficam em `tools/`, excluídos dos exports de produção. O
export de revisão usa um projeto temporário independente em `artifacts/`; não
altera o boot, o projeto, as telas ou o runtime-lock do jogo. Os dois módulos
novos têm status `prototype`, sem pins de produção. O ator usa 0.2.2 e a base da
sala continua em 0.1.0. Os atores 0.1.0, 0.2.0 e 0.2.1 ficam preservados.

No projeto-fonte, a referência em `review/` é lida como PNG bruto, preservando
sua exclusão dos imports de produção. O export Web de estudo importa sua própria
cópia. A abertura nativa e os controles Web foram conferidos nos dois caminhos.

## Evidência e limites

A QA verifica identidade do PNG, alfa, cobertura dos recortes e pivôs em pixels
opacos. O teste nativo verifica a pose inicial, alcance, botas rígidas, alternância
dos contatos, dois levantamentos distintos, fechamento da malha e apoio fixo.
A revisão Web aciona controles reais, observa ambas as ordens das pernas e
compara o quadro final ao inicial. Diferença zero nessa comparação significa
retorno técnico à mesma imagem; não mede qualidade artística.

A primeira máscara deixou 81 pixels do contorno da calça de fora e foi corrigida.
A primeira captura demorou dentro de um screenshot e perdeu a segunda janela
de passada; a captura seguinte observa a reprodução sem interrompê-la com
screenshots. As tentativas ficam preservadas nos artefatos locais.

Na reprodução em software, foram observados 17 estados de marcha na primeira
captura completa, cobrindo todas as alternâncias. A checagem por quantidade de
estados foi substituída por cobertura de pelo menos cinco mudanças de apoio
ao longo dos três ciclos. Transformações e pesos do rig foram pré-calculados
para reduzir o custo, mantendo os testes de identidade, alcance e fechamento.
O piloto 0.1.0 passou seis checagens de fonte, oito nativas e sete Web; o quadro
da cena ao terminar é idêntico ao inicial. Isso não certifica fluidez em hardware.

O download da folha de quatro quadros falhou neste executor; o domínio retornado
não está na política de rede. Essa folha e o GIF não foram usados no piloto.
As duas referências aprovadas foram materializadas normalmente.

## Correção controlada 0.2.0

A revisão de `e077079` encontrou joelhos comprimidos, botas cruzadas e parte
superior rígida. A versão 0.1.0 forçava as duas solas para uma linha central;
0.2.0 conserva faixas distintas e acompanha o pequeno movimento dos quadris
projetados. A compensação vertical respeita o alcance original dos membros.

Na amostragem do ciclo, a maior flexão do joelho de apoio caiu de 58,97° para
25,72°; a compensação vertical máxima caiu de 20 para 7,08 pixels da origem.
Os limites opacos das botas mantêm 54 pixels de separação na origem (35,1 na
escala do estudo). Isso verifica geometria, sem estabelecer qualidade artística.
Onze casos nativos e dez Web cobrem o novo contrato, incluindo movimento
independente dos braços/mochila e fechamento da malha superior.

A cena informa explicitamente que é um candidato sobre base estática, sem
casa jogável. Brasa, sofá e chão continuam fundidos à base visual desta prova.

## Cobertura da cintura 0.2.1

A revisão independente de `41e51da` encontrou piso aparecendo dentro da calça
logo abaixo da cintura, aproximadamente em 0,5 e 1,3 segundos do trecho. As
malhas das duas pernas se afastavam do casaco e uma da outra durante a passada,
apesar de o PNG original ser opaco nessa região. A versão 0.2.1 prende o topo da
calça e a costura interna ao mesmo movimento da pelve; a influência da coxa
aumenta gradualmente abaixo dessa junção. Não há painel de cor ou novo desenho
cobrindo o defeito. O alcance, os pés, os joelhos e o rig superior são preservados.

O novo teste calcula a cobertura a partir dos triângulos deformados, seus UVs
e o alfa da textura. Verifica o interior opaco abaixo da cintura e acima da
abertura natural das pernas: retângulo [580,786,142,80] na imagem original,
amostrado a cada dois pixels. São 460.080 amostras em 129 fases de ciclo e 33
níveis de acomodação, com alfa mínimo exigido de 0,95. A versão anterior falha
em 62.277 amostras, chegando a alfa zero; a correção tem zero descobertas e
alfa mínimo 0,9882. Isso cobre a abertura reportada, sem julgar o tecido ou
substituir a inspeção do vídeo. Os doze casos nativos passam e mantêm os mesmos
resultados geométricos da versão 0.2.0.

O PNG aprovado e as versões anteriores não mudaram. O teste de recortes da
imagem parada continua separado: ele sozinho não detectava essa falha dinâmica.

## Orientação dos triângulos 0.2.2

A revisão de `1b9812f` confirmou a cintura, mas encontrou inversão de triângulos
no joelho distante em ciclo 0,22. Misturar as rotações da coxa e da canela em
apenas 32 pixels da origem fazia a malha dobrar sobre si mesma. A junção da
bota e a transição lateral da costura também precisavam de uma faixa maior.
0.2.2 distribui a deformação por faixas mais largas: joelho com 96 pixels para
cada lado, bota entre 80 pixels acima e oito abaixo do tornozelo, e ligação à
pelve entre y=820 e y=970, com transição lateral de 120 pixels. A bota continua
inteiramente rígida abaixo de y=1038. Sem mudança do PNG, das trajetórias dos
pés, do IK, do tronco, dos braços ou da mochila.

A regressão compara cada triângulo deformado à orientação de sua referência,
incluindo recortes pequenos do contorno. São 1.584 triângulos por pose, nas
duas pernas e no corpo superior, com 4.985 poses e 7.896.240 verificações:
1.001 fases do ciclo, 129 níveis da acomodação usada pelo trecho e uma malha
adicional de 257 fases por 15 níveis intermediários de acomodação. Inclui o
ciclo 0,22 exato. Um triângulo de área nula já presente na geometria original
é registrado e excluído da razão de áreas. A versão anterior produz 28.048
inversões nesse teste; 0.2.2 produz zero inversões e zero áreas abaixo de 5%
da referência. A menor razão de área é 0,20365.

Os treze casos nativos passam. A cobertura da cintura continua sem amostras
descobertas, e os resultados de apoio, separação das botas, flexão dos joelhos
e movimento independente da parte superior permanecem iguais aos de 0.2.1.
Essa amostragem geométrica não substitui a avaliação visual da deformação do
tecido ou a revisão de Pedro. O estudo continua candidato, sem promoção.

Ainda precisam de julgamento de Pedro a proporção em relação a Brasa, o contorno
em escala real, as junções sob o casaco e a leitura da passada em três quartos.
As botas ainda transladam sem rolar sobre a ponta; o trecho curto e a rigidez
residual dos tecidos continuam limites da técnica de recorte.
O cenário completo da casa, as demais vistas e as outras animações ficam fora
desta fatia. Não há aprovação estética, promoção dos módulos ou integração no
fluxo principal do jogo nesta entrega.

Na integração da branch, regenerar a união dos índices de assets com
`python tools/assets.py build`; o runtime-lock permanece inalterado. Os Actions
permanecem desativados por solicitação de Pedro. Esta entrega registra somente
validações locais.
