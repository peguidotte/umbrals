# V05-ART-08B — Pietro candidato na casa real

Experimento em branch separada sobre a main `60b4e30`. Não substitui a casa ou
o ator de produção. O boot opcional instancia `scenes/main.tscn`, usa o
`RefugeRoom` real e troca somente seu canvas por uma subclasse experimental.
Cenário, escada, câmera, hotspots, grimório, fluxo da run e saves continuam nos
donos existentes. O piloto aquático e os demais contratos da main são preservados.

**O cenário atual não está aprovado.** Pedro rejeitou seu visual e ainda falta
adaptá-lo à direção pixel aprovada. A legenda do experimento informa essa
pendência. Esta prova compara personagem e Umbral no ambiente real atual;
não apresenta uma casa nova nem fecha a direção artística.

## Comparação e controles

**Pietro atual** mostra o renderer de produção; **Pietro candidato** mostra o
rig experimental 0.4.1 na mesma posição, câmera e escala de mundo. A imagem
aprovada permanece byte a byte igual. Escala 0,5, próxima da altura do ator
atual; esquerda é espelhamento da única vista de três quartos disponível.
**Enquadrar sala** é um controle explícito de revisão que reposiciona apenas
o experimento. Não é uma ação da casa de produção.

Brasa é um `CreatureRig` vivo, usando `BattleArt.texture("umbrals/ember")` e o
perfil de chão do runtime atual, separado da textura da casa. Não é o Brasa
fundido à prancha estática anterior nem a arte nova ainda fora da main. Sua
presença aqui não cria companheiro, diálogo, save ou comportamento de jogo.

**Reduzir movimento** aciona a preferência real do jogo. Pietro usa a pose
neutra, Brasa recebe `reduced_motion`, seu estado transitório é reiniciado e
sua malha e relógio de repouso ficam estáticos. Desativar a preferência retoma
o movimento. Câmera e deslocamento seguem a implementação original da casa,
incluindo o enquadramento imediato já existente para movimento reduzido.

O antigo botão de caminhada lenta foi removido. O host não chama mais o
callback de física da casa nem escala seu delta: observa o resultado depois
do controlador real. Todas as opções conservam 330 pixels de mundo por segundo.
Câmera lenta, quando útil para revisão, deve ser uma reprodução do vídeo gravado.

## Cadência e deformação 0.3.0

0.2.2 cobria 80 pixels de mundo por ciclo nessa escala, o que resultava em 8,25
passos/s à velocidade normal. 0.3.0 amplia o deslocamento para 220 pixels por
ciclo: 3 passos/s, sem reduzir a velocidade lógica ou limitar o relógio enquanto
os pés deslizam. A fase continua dirigida pela distância percorrida.

Para essa amplitude, a antiga mistura de rotações dobrava triângulos estreitos
do recorte quadriculado. O novo modo usa faixas horizontais com todas as alturas
dos vértices das máscaras e interpola deslocamentos entre articulações. As
máscaras e o PNG permanecem iguais aos de 0.2.2. A cintura compartilha a pelve;
as botas e a faixa clara acima delas continuam rígidas a partir de y=970
da origem. O modo antigo e todas as versões anteriores ficam
preservados e continuam passando seus testes.

A regressão da passada maior cobre 4.985 poses e 4.860.375 triângulos: zero
inversões ou colapsos, razão mínima de área 0,12989 e cintura sem amostras
descobertas. O teste de integração mede 3 passos/s em 330 pixels percorridos,
deriva zero de vértices reais da bota de apoio e nenhuma interferência do host
na posição ou câmera após o callback original.

Os apoios durante a caminhada são equilibrados em torno do corpo: os contatos
alternam distâncias de 115 e 105 pixels de mundo. Isso evita ampliar apenas a
amplitude mantendo uma passada curta ou para trás e outra longa. A pose parada
larga aprovada permanece intacta; a acomodação desloca os apoios para caminhar.
Os pés alternam a ordem projetada e seus contornos podem se sobrepor na passagem.
A compensação vertical máxima é 23,45 pixels da origem, ou 11,73 pixels de mundo.
A leitura dos joelhos, tecido, passagem e sobreposição continua sujeita à revisão
visual, sem aprovação artística automática pelos testes.

## Volume da calça e correção do gate 0.4.1

A revisão de 0.3.0 encontrou a calça reduzida a uma faixa em X sobre as barras.
O teste de áreas orientadas passava porque os triângulos comprimidos mantinham
sua orientação. A medição inicial de quatro alturas reproduziu o pinçamento,
registrando 6,78% de largura transversal em uma dessas seções.

0.4.0 passou a deslocar faixas uniformemente, compensar largura e cobrir a
junção superior com uma peça da pelve amostrada do mesmo PNG. A composição
continua distante/próxima/pelve/corpo, com sobreposição opaca. A comparação
visual removeu o X fino, mas o gate de volume ainda tinha uma lacuna: os 61,33%
eram o mínimo de quatro alturas, não um mínimo global. A revisão independente
apontou 54,85% em y=964/fase 0; reproduzimos exatamente esse resultado e 52,72%
em y=963 ao medir cada linha entre 900 e 970. O vídeo e os dados anteriores
continuam evidência da candidata anterior, com essa limitação reconhecida.

0.4.1 acomoda juntos o deslocamento e sua tangente até a barra rígida, sem um
afinamento de largura independente enquanto o tecido ainda se desloca de lado.
As faixas são subdivididas em colunas de até 32 pixels de origem; isso evita
que uma única diagonal atravessando a perna inteira gere tangentes distintas.
Os pontos de mudança da deformação também viram linhas explícitas da malha.
As máscaras mantêm sua área (erro relativo abaixo de 0,000001); PNG, material
do cabelo, pelve, apoios e versões anteriores permanecem preservados. Não há
novas poses geradas. Barras e botas continuam rígidas desde y=970.

A regressão agora mede cada linha inteira de origem de 784 a 970, nos centros
dos pixels, usando tangentes de +/-4 pixels. São 187 alturas por perna e 2.465
poses, com fases intermediárias de acomodação espaçadas em 1/128 de ciclo:
921.910 seções. O mínimo **amostrado** de largura é 91,33%, e o de altura,
82,62%, mantendo os limites de 60%/80%. No caso exato de y=964/fase 0, a largura
passa de 54,85% para 104,37%. O teste inclui o falso positivo das quatro alturas
e o reproduzido em y=963/964. Trata-se de uma grade finita de poses/seções, não
de prova de volume contínuo global ou de uma nota estética.

O teste de orientação cobre 4.985 poses e 9.202.310 triângulos: zero inversões
ou colapsos e razão mínima de área 0,33415. As 460.080 amostras de cintura
continuam cobertas. A comparação controlada de oito fases usa o renderer real
para 0.4.0/0.4.1 e fica separada da casa jogável:

```bash
python tools/studies/pietro_volume/build_preview.py --output artifacts/pietro-volume-poses
```

A candidata precisa de nova revisão visual independente e de Pedro; o teste
não promove o personagem nem aprova a casa. Botas rígidas e deformação do
tecido nas poses abertas continuam pontos para inspeção visual.

## Brilho do cabelo

Pedro esclareceu que o destaque excessivo estava no cabelo. O material 0.3.0
seleciona em UV apenas a borda dourada do cabelo e reduz sua intensidade para um
castanho/cobre discreto. Alfa, geometria e PNG aprovado permanecem intactos.
O material fica num nó de desenho exclusivo de Pietro; chão, cenário, Brasa,
rosto, olhos, roupa e acessórios não recebem a correção. **Luz original** permite
comparar o ajuste no mesmo quadro, sem reposicionar o personagem.

Foi criada uma única referência tonal por edição de imagem. Ela alterou também
pixels fora do cabelo e do alfa; por isso não substitui a textura aprovada.
A implementação é o material localizado, verificado por comparação de pixels
na renderização real. Não houve geração de novas folhas ou poses.

Entrada e saída da passada usam acomodação de 0,2 segundo, conservando a fase
se o movimento for retomado. Não há novas poses de despertar, escada ou giro.
O experimento começa na sala e usa pose neutra nesses estados fora do estudo
de caminhada. Botas sem rolamento, outras vistas, desempenho em hardware e
integração definitiva permanecem abertos.

## Reprodução e validação

```bash
source tools/environment.sh
XDG_DATA_HOME="$PWD/artifacts/pietro-house-user" godot --path . tools/studies/pietro_house/study.tscn
XDG_DATA_HOME="$PWD/artifacts/pietro-house-test-user" godot --headless --path . --script tools/studies/pietro_house/test_house.gd
godot --headless --path . --script tools/studies/pietro_house/test_gait.gd
godot --headless --path . --script tools/studies/pietro_pixel/test_rig.gd
python tools/studies/pietro_house/build_preview.py --output artifacts/pietro-house-preview
python tools/studies/pietro_house/review.py --build-dir artifacts/pietro-house-preview/build --output artifacts/pietro-house-review
```

O build copia as fontes atuais para um projeto temporário e troca somente seu
boot e diretório de usuário. Presets e projeto de produção permanecem intactos;
`tools/` continua excluído do export normal. Assets prototype, sem pins novos.
Scripts de produção, conteúdo, Rules, saves, runtime-lock, registry e baseline
não são modificados. Os testes de catálogo, integridade e arquitetura seguem
proporcionais; evidência focada não é aceitação integral. Actions segue desativado.

Na revisão atual passaram 20 verificações da integração, 14 da passada maior
e 13 do rig anterior. O teste de movimento reduzido compara a malha e o relógio
do Brasa; a revisão Web também compara seus pixels renderizados entre quadros.
RNG, equipe, checkpoint e estatísticas permanecem iguais após caminhada e
acessibilidade. A rodada Web 0.4.1 passou 19 verificações, com duas caminhadas de 360 pixels
por inputs reais e vídeo. Uma tentativa anterior parou num timeout ao localizar
o canvas antes do A/B, sem erros registrados da aplicação; a repetição no mesmo
build passou e ambas as tentativas foram preservadas. Catálogo (556 verificações),
integridade de 102 releases/363 arquivos, imutabilidade contra `origin/main` e
arquitetura passaram nos gates focados. Não foi repetida a aceitação integral
do jogo.
Nenhum resultado substitui o julgamento de Pedro.

## Evidência anterior preservada

`374bd3e` e seu vídeo registram a comparação inicial, 12 testes próprios, 13 do
rig, 79 da casa original, 556 de catálogo, integridade e arquitetura, e 14 Web.
Esse candidato tinha cadência alta, modo lento por delta e não propagava a
preferência ao Brasa. Os arquivos e vídeos anteriores permanecem no histórico
e na Library; não são reclassificados como evidência da correção atual.

Sem merge, promoção ou aprovação de cenário nesta entrega.
