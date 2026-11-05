# V05-ART-08 — Pietro pixelado: comparação parada e caminhada curta

Piloto sobre a main `8d514bf`, separado das animações anteriores. Pedro aprovou
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
folha de personagem gerada por IA. Face, casaco, mochila e braços ficam estáveis;
as duas pernas são articuladas e as botas transladam sem deformação ou rotação.

A base da sala recebeu uma única edição dirigida para remover o Pietro que
estava fundido à imagem. Brasa permanece uma referência estática dentro dessa
base, sem animação ou comportamento novo. A saída tem 1585×992; a referência
original tem 1586×992. Portanto não se afirma que Brasa ou o cenário tenham
permanecido idênticos pixel a pixel. O rodapé conceitual é recortado pelo renderer.

A altura de Pietro, os pontos de apoio e o quadro são calibrados à cena aprovada.
O estudo tem resolução lógica 1600×1000, incluindo controles abaixo da área de
1586×880 da cena. Filtro nearest, escala do ator 0,65 e pivô [620,1130]. A marcha
é dirigida pela distância, com apoio plantado durante cada meia passada e
levantamento separado da outra perna. O ciclo fecha matematicamente. Somente a
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
novos têm status `prototype` e versão explícita 0.1.0, sem pins de produção.

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
O piloto final passou seis checagens de fonte, oito nativas e sete Web; o quadro
da cena ao terminar é idêntico ao inicial. Isso não certifica fluidez em hardware.

O download da folha de quatro quadros falhou neste executor; o domínio retornado
não está na política de rede. Essa folha e o GIF não foram usados no piloto.
As duas referências aprovadas foram materializadas normalmente.

Ainda precisam de julgamento de Pedro a proporção em relação a Brasa, o contorno
em escala real, as junções sob o casaco e a leitura da caminhada. Braços fixos,
recolhimento dos pés e deformaçōes da calça são limites desta prova pequena.
O cenário completo da casa, as demais vistas e as outras animações ficam fora
desta fatia. Não há aprovação estética, promoção dos módulos ou integração no
fluxo principal do jogo nesta entrega.

Na integração da branch, regenerar a união dos índices de assets com
`python tools/assets.py build`; o runtime-lock permanece inalterado. Os Actions
permanecem desativados por solicitação de Pedro. Esta entrega registra somente
validações locais.
