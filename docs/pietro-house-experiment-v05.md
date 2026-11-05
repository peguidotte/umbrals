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
rig experimental 0.4.0 na mesma posição, câmera e escala de mundo. A imagem
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

## Volume da calça 0.4.0

A revisão de 0.3.0 encontrou a calça reduzida a uma faixa em X sobre as barras.
O teste de áreas orientadas passava porque os triângulos comprimidos mantinham
sua orientação. Uma medição independente, ligada às UVs de seções opacas reais
da calça, reproduz a falha: largura transversal mínima de 6,78% da original.

0.4.0 desloca cada faixa horizontal uniformemente entre a pelve e a barra,
compensa sua largura transversal e limita a compressão vertical. Uma peça de
pelve amostrada do mesmo PNG cobre a junção superior; as pernas são desenhadas
em ordem distante/próxima, com sobreposição opaca na passagem. O PNG, máscaras
originais das pernas, apoios, rig antigo e material do cabelo ficam preservados.
Não há novas poses geradas. As barras e botas continuam rígidas desde y=970.

A regressão de volume mede oito seções por pose em 665 poses, incluindo
entrada, saída e fases intermediárias: largura mínima 61,33% e altura mínima
84,91%. Os limites de regressão são 60%/80%; o candidato anterior falha no
critério de largura. Não se trata de conservação exata do volume nem de uma
nota estética. O teste de orientação inclui agora a peça da pelve: 4.985 poses,
6.206.325 triângulos, zero inversões/colapsos, razão mínima de área 0,33415.
As 460.080 amostras de cintura continuam cobertas.

A comparação controlada mostra oito fases de 0.3.0/0.4.0 com o renderer real,
separada da casa jogável. Ela pode ser reproduzida com:

```bash
python tools/studies/pietro_volume/build_preview.py --output artifacts/pietro-volume-poses
```

Na inspeção desses quadros, a faixa fina em X desaparece e as barras mantêm
cobertura de tecido. Há alguma distorção do tecido nas poses abertas e não há
rolamento das botas. A candidata precisa de nova revisão visual independente
e de Pedro; o teste não promove o personagem nem aprova a casa.

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

Na revisão atual passaram 20 verificações da integração, 11 da passada maior
e 13 do rig anterior. O teste de movimento reduzido compara a malha e o relógio
do Brasa; a revisão Web também compara seus pixels renderizados entre quadros.
RNG, equipe, checkpoint e estatísticas permanecem iguais após caminhada e
acessibilidade. A rodada Web 0.4.0 passou 19 verificações, com duas caminhadas
de 360 pixels por inputs reais e vídeo. Catálogo (556 verificações), integridade
de 101 releases/360 arquivos, imutabilidade contra `origin/main` e arquitetura
passaram nos gates focados. Não foi repetida a aceitação integral do jogo.
Nenhum resultado substitui o julgamento de Pedro.

## Evidência anterior preservada

`374bd3e` e seu vídeo registram a comparação inicial, 12 testes próprios, 13 do
rig, 79 da casa original, 556 de catálogo, integridade e arquitetura, e 14 Web.
Esse candidato tinha cadência alta, modo lento por delta e não propagava a
preferência ao Brasa. Os arquivos e vídeos anteriores permanecem no histórico
e na Library; não são reclassificados como evidência da correção atual.

Sem merge, promoção ou aprovação de cenário nesta entrega.
