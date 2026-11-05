# V05-ART-08B — Pietro candidato na casa real

Experimento em branch separada sobre a main `60b4e30`, preservando o piloto
aquático e os demais contratos atuais. Não substitui a casa ou o ator de produção.
O boot opcional instancia `scenes/main.tscn`, usa o `RefugeRoom` real e troca
somente seu canvas por uma subclasse experimental. Cenário, escada, câmera,
hotspots, grimório, fluxo da run e saves continuam nos donos existentes.

O botão **Pietro atual** mostra o renderer de produção; **Pietro candidato**
mostra o rig 0.2.2, na mesma posição, câmera e escala de mundo. A imagem aprovada
permanece byte a byte igual. Escala do piloto 0,5, próxima da altura do ator
atual; esquerda é espelhamento da única vista de três quartos disponível.
**Enquadrar sala** é um controle explícito de revisão: reposiciona apenas esta
cena experimental. Não é uma ação da casa de produção.

Brasa é um `CreatureRig` vivo, usando `BattleArt.texture("umbrals/ember")` e o
perfil de chão do runtime atual, separado da textura da casa. Fica no mesmo
piso do protagonista para comparar tamanho e acabamento. Não é o Brasa fundido
à prancha estática anterior nem a nova arte de Brasa ainda fora da main. Sua
presença aqui não cria companheiro, diálogo, save ou comportamento de jogo.

A câmera e a casa são as atuais, cujo visual Pedro rejeitou. Esta prova compara
o candidato nesse ambiente real; não apresenta uma nova casa ou aprovação de
direção artística.

## Movimento e limites

A velocidade padrão conserva os 330 pixels de mundo por segundo da casa.
O ciclo é dirigido pela distância percorrida; com amplitude 40 da origem e
escala 0,5, cada ciclo cobre apenas 80 pixels de mundo. Isso produz cadência
alta em velocidade normal, um limite importante do passo curto já apontado
pela revisão. As botas continuam rígidas, sem rolamento desenhado.

**Caminhada lenta** é uma opção explícita do experimento: o host fornece um
delta menor ao mesmo controlador, resultando em 100 pixels de mundo por segundo.
Ela permite examinar a passada; não altera `HouseSpace.SPEED`, controles ou
contratos da casa de produção. A legenda identifica a velocidade em uso.
Entrada e saída da passada usam acomodação de 0,2 segundo, conservando a fase
se o movimento for retomado. A malha 0.2.2 mantém as correções de cintura e
orientação de triângulos. A aprovação do rig em estudo não aprova essa adaptação.

Não há novas poses de despertar, escada ou giro. O experimento começa na sala
e usa a pose neutra nesses estados fora do estudo de caminhada. Não interpretar
o deslocamento da casa como animação dedicada. Permanecem abertos julgamento
visual do tecido, cadência em hardware, outras vistas e integração definitiva.

## Reprodução e validação

```bash
source tools/environment.sh
XDG_DATA_HOME="$PWD/artifacts/pietro-house-user" godot --path . tools/studies/pietro_house/study.tscn
XDG_DATA_HOME="$PWD/artifacts/pietro-house-test-user" godot --headless --path . --script tools/studies/pietro_house/test_house.gd
godot --headless --path . --script tools/studies/pietro_pixel/test_rig.gd
python tools/studies/pietro_house/build_preview.py --output artifacts/pietro-house-preview
python tools/studies/pietro_house/review.py --build-dir artifacts/pietro-house-preview/build --output artifacts/pietro-house-review
```

O build de revisão copia as fontes atuais para um projeto temporário e troca
somente seu boot e diretório de usuário. Os presets e o projeto de produção
permanecem intactos; `tools/` continua excluído do export normal. Os assets do
piloto continuam prototype, sem pins novos. Não foram modificados scripts de
produção, conteúdo, Rules, saves, runtime-lock, registry ou baseline.

O teste nativo verifica a integração, fonte real do cenário e de Brasa, velocidade
normal e lenta, A/B sem reposicionamento, acomodação e preservação de RNG, equipe,
checkpoint e estatísticas. A revisão Web usa botões, teclado e o grimório reais,
grava vídeo e observa câmera e movimento. Os testes do rig, da casa original,
catálogo, integridade e arquitetura continuam separados e proporcionais.
Evidência focada não é aceitação integral ou aprovação artística; Actions segue
desativado e não é atribuído como aprovado. Sem merge ou promoção nesta entrega.

Resultado local: 12 verificações do experimento, 13 do rig, 79 da casa original,
556 de catálogo, integridade de 99 releases/354 arquivos e arquitetura passaram.
A revisão Web passou 14 verificações com inputs reais, incluindo A/B, duas
velocidades, câmera, retorno à pose neutra e abrir/fechar o grimório real.
O primeiro lançamento da revisão omitiu `?test=1` e falhou ao consultar o snapshot
de diagnóstico; o lançamento corrigido usa a flag existente, sem mudar a bridge.
Uma sequência posterior reenquadra a sala entre os percursos para que Brasa não
encubra os joelhos. As tentativas anteriores permanecem nos artefatos locais.

Na inspeção, o candidato tem altura próxima à do ator atual, com contorno mais
marcado; ambos aparecem sobre o mesmo cenário e piso. O vídeo mostra a cadência
alta em velocidade normal e o percurso lento explicitamente identificado. São
evidências para revisão de proporção e integração, não aprovação de estilo,
movimento ou desempenho em hardware.
