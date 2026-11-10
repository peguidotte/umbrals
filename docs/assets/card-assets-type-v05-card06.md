# V05-CARD-06 — nomes centrados e serifada das cartas

O piloto optativo Foli/Lonlon mantém as molduras, pinturas, cores e o leque
existentes. Esta fatia corrige o nome do golpe deslocado para a esquerda e
substitui a serifada genérica das duas placas pela Cormorant Garamond Bold
já licenciada e versionada no projeto. Não identifica a fonte exata do anexo.

## Causa e implementação

`title_content_rect()` retirava 11% da largura apenas do lado direito quando
o alvo/custo estava presente. Isso deslocava o centro do texto em 5,5% da
largura do canvas. A reserva agora é simétrica: o título mantém o centro da
placa, com ou sem alvo. A largura disponível continua respeitando o custo.

A placa do golpe usa tamanho base 18, com ajuste pela largura/altura real;
a placa do dono mantém base 15. Medição e desenho usam a mesma fonte e
geometria, inclusive `PowerCard.title_fits()`. Títulos do piloto permanecem
em uma linha. Indicadores de alvo, custo, pendência e valores conservam a
fonte anterior para manter sua legibilidade pequena.

O primeiro ciclo Cormorant renderizou Light apesar de solicitar `wght: 700`.
No Godot 4.6.3 usado aqui, a chave textual `wght` foi ignorada. O diagnóstico
mediu a mesma largura de `Gota serena` em 32 pontos, 147, para pesos 300/700.
O identificador OpenType retornado por `TextServer.name_to_tag("wght")`
aplica o peso real: 147 no Light, 150 no Bold. Não é negrito sintetizado.
O teste nativo agora verifica também a mudança efetiva das métricas, além
do centro estável e do encaixe dos nomes. Referência da API:
[FontVariation](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html).

## Ciclos e evidências

- `artifacts/card-type-center-browser/`: primeiro ciclo, tecnicamente verde,
  mas rejeitado na inspeção por fonte fina. Preservado como diagnóstico.
- `artifacts/card-type-bold-browser/`: Bold real, 759 checks Web. A inspeção
  detectou perda de leitura do rótulo auxiliar, corrigida em seguida mantendo
  a fonte anterior fora das duas placas.
- `artifacts/card-type-final-build/`: 51 checks de apresentação, exportação
  e catálogo empacotado passaram após essa separação de fontes.
- `artifacts/card-type-final-manual/`: 12 PNGs originais e snapshots, sem
  redimensionamento posterior, com Foli/Lonlon em repouso/seleção, 720p/1080p
  e seleção com texto ampliado. Entradas reais de mouse e opções: 51 checks,
  zero erros. Todos os 12 PNGs foram abertos e inspecionados.
- Fechamento integral congelado: `artifacts/card-type-final-acceptance/`.
  Consultar seu `run.json` e a revisão local para o resultado efetivo; o
  caminho não antecipa aprovação. Baseline: `card-fan-final-acceptance`.

No destaque, o nome longo de Foli fica completo e central; custo 1/indicador
de área permanecem separados. Em Lonlon, Gota serena fica central na placa,
com retrato, sinal azul, custo 1 e nome/UID do destinatário visíveis. Em
repouso, outras cartas ainda encobrem partes dos títulos pela sobreposição
do leque; isso é registrado separadamente de clipping do texto na placa.

## Limites de fidelidade e escopo

O anexo aprovado está visível na conversa. Seus bytes originais continuam
indisponíveis neste executor; não houve comparação conjunta mensurável com
o raster original nem identificação tipográfica exata. Cormorant mantém a
direção serifada e botânica/dourada existente; a aprovação subjetiva de Pedro
continua aberta. `design-qa.md` permanece `final result: blocked` para a
fidelidade integral. A galeria candidata não é o arquivo da referência.

Sem mudança de assets, catálogo, runtime-lock, regras ou saves. Prévia
continua optativa, produto 0.3.0; 6/73 pares candidatos, 67 ilustrações e duas
molduras faltantes, sem aprovação artística. Sem push, merge, deploy ou
exportação de screenshots para Library/Space. O bloqueio anterior de `file://`
no navegador não foi contornado; os PNGs são inspecionados pelo mecanismo
de imagem suportado.
