# V05-CARD-04 — peças das cartas a partir do anexo reenviado

Pedro reenviou a imagem de 1280 × 720 e pediu atenção às molduras e à composição
de cada carta. O anexo foi visualizado e fornecido diretamente à ferramenta de
imagem. O bloqueio de entrada da etapa anterior foi resolvido pelo novo anexo;
não houve repetição ou contorno das transferências bloqueadas da Library.

## Aplicação da referência

| Parte | Implementação desta fatia |
|---|---|
| Família Foli | Nova moldura de raízes de madeira marrom, folhas verdes e filetes dourados; centro transparente, sem placas embutidas. |
| Família Lonlon | Nova moldura de faixas de água azul/ciano, dourado e orbe superior; permanece azul no exemplo de golpe de Bosque. |
| Tipo do golpe | Placa superior, placa do dono e contorno fino da foto seguem Bosque/Água; não seguem a natureza do dono. |
| Ilustração | Janela maior (84% da largura, 64% da altura), com cantos curvos recortados na própria pintura. Não há a borda branca espessa nem a faixa preta de valores sobre a cena. |
| Letras | Fonte serifada licenciada já existente, com reforço leve do traço. Títulos priorizam uma linha; nomes/custo são texto nativo. |
| Alvo/custo | Retrato circular superior direito, sinal de cura/ataque e custo real logo abaixo; dados vêm da projeção pública existente. |
| Seleção | Realce usa a silhueta da própria moldura, sem retângulo quadrado externo. Valores e marca de prévia ficam abaixo da placa do dono. |
| Gota serena | Nova cena com Lonlon, Foli e a água de cura, com a composição da referência como entrada. A ilustração é fixa por poder; o retrato indica o destinatário real, que pode ser outro indivíduo. |
| Lonlon/Bosque | Ilustração isolada de lâminas verdes. Continua demonstração não aprendível, sem mudança de conteúdo/regras. |

O modo `?test=1&card_gallery=1&card_concept=1` mostra as seis cartas da referência
num leque **estático e somente de leitura**. A galeria técnica de sete exemplos
continua cobrindo forma adulta, compartilhamento de tipo e moldura ausente.
A mão real mantém quantidade, hit areas, teclado/toque e layout existentes; a
carta em mira usa o detalhe ampliado da fatia anterior. O leque conceitual não
foi apresentado como nova disposição do HUD de combate.

## Assets e proveniência

- `ui/card-frame-{moss,dew}@0.2.0`: dois PNGs originais RGBA 1024 × 1536,
  alpha real, inclusive no interior. Os 0.1.0 anteriores não foram alterados.
- `ui/card-nature-{forest,water}@0.2.0`: quatro placas derivadas apenas por
  separação/crop determinístico de duas folhas geradas; contorno da foto em SVG
  nativo, fino e sem branco. Masters originais ficam em `review/` com hashes.
- `ui/card-nature-{fire,lightning}@0.2.0`: preservam as placas provisórias
  anteriores e usam o contorno fino; não existe novo conceito aprovado desses
  tipos nesta imagem.
- `umbrals/card-art-dew@0.2.0`: cura (1173 × 1341) e exemplo de Bosque; os
  originais gerados permanecem intactos. Cinco ilustrações jogáveis anteriores
  continuam por referência exata, sem cópia ou mudança em seus PNGs.
- `umbrals/card-target-{moss,dew}@0.1.0`: dois crops de face, 550 × 550, da cena
  de cura. São imagens independentes de alvo; as demais formas/retratos ainda
  reutilizam suas referências existentes e carecem de revisão artística.
- `ui/power-card-system@0.3.0`: novo release prototype, com dependências exatas.
  Somente a flag de desenvolvimento seleciona essa versão. Runtime-lock,
  conteúdo, regras, progressão e saves permanecem.

`tools/asset_authoring/build_card_reference.py` registra o preparo. Ele recusa
sobrescrita de versões, preserva os masters com metadata e usa o renderizador
SVG e catálogo existentes. O exportador de demanda usa agora o mesmo ambiente
XDG do harness também em sua chamada standalone, evitando escrita em diretório
de usuário sem permissão. Não foi criado outro pipeline de assets.

## Validação e revisão

Primeira montagem: `artifacts/card-reference-focus/` preserva a falha de inventário
de revisão; o novo exemplo demonstrativo precisava ser listado explicitamente.
`artifacts/card-reference-components/` passou após esse registro, sem conceder
aprendizado. Uma tentativa de autoria incompleta por cache Godot sem permissão
está preservada em `artifacts/card-reference-authoring-incomplete/`.

`artifacts/card-reference-browser/`: 688 verificações Web passaram, com cinco
formatos normal/ampliado, galeria técnica, seis cartas conceituais, batalha
real, inspeção, pilha e toque. A inspeção dos PNGs mostrou as novas peças
compostas, e revelou título em duas linhas e legenda sobreposta no leque;
foram ajustados para uma linha e rodapé livre antes do fechamento.
Na revisão seguinte em 1080p, o custo podia encobrir o fim de títulos. O custo
agora usa o canto superior livre enquanto não há alvo; quando o retrato está
presente, o texto reserva o espaço ocupado pelo custo abaixo dele. O teste de
texto mede essa mesma região, incluindo todos os nomes de poderes existentes.
`artifacts/card-reference-final-layout/`: assets, UI e input passaram após esses
ajustes. O artefato de foco final e o fechamento integral são, respectivamente,
`artifacts/card-reference-final-browser/` e `artifacts/card-reference-acceptance/`;
consultar seus relatórios para o resultado, sem antecipá-lo neste registro.
O ajuste final de custo/título tem foco em `artifacts/card-reference-cost-layout/`
e revisão visual dedicada em `artifacts/card-reference-cost-review/`.

O novo desenho deve ser julgado pelas capturas reais, comparado ao anexo.
Geração/reconstrução pode variar detalhes de contorno e poses: não é um recorte
pixel a pixel do concept nem aprovação artística automática. A revisão de Pedro
continua necessária. Permanecem 67 combinações sem arquivo, seis pares jogáveis
candidatos sem aprovação e duas famílias sem moldura (ember/volt). O exemplo
não jogável não aumenta a cobertura de 6/73. Promoção de produção é recusada.

Conservados mipmaps, pixels originais e filtro próprio das cartas. A política
Web de resolução CSS em Retina não foi alterada. Não houve merge, push, deploy,
exportação de screenshots para Library/Space ou alteração de regras.
