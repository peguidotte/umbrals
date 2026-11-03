# Estilo visual componentizado

`content/styles/moonlit.tres` é a raiz de apresentação. O schema `visual_style.gd`
expõe fontes, cores semânticas, superfícies e estados de botão, bordas, foco, sombras,
tipografia, `CardStyle` e `MotionStyle`. O Inspector pode editar esses Resources.

`ui/style.gd` resolve a raiz de apresentação; `kit.gd` monta o Theme a partir dela.
Cartas, botões rúnicos, barras, mão, efeitos e feedback consultam o mesmo Resource.
Mudar uma cor semântica não exige procurar cada `_draw()`. Métricas específicas de
layout permanecem nos componentes que as possuem. Trocar de estilo em runtime não
é uma preferência do jogador nesta versão; após editar a definição, reinicie a cena.

O ambiente é independente do estilo de UI: `EnvironmentDefinition` controla arte,
luz, vaga-lumes e música. Identidade visual de criatura/poder continua no pacote da
espécie; estilo não substitui seus assets nem altera regras.

```bash
source tools/environment.sh
godot --path . scenes/style_gallery.tscn
python tools/preview_style_gallery.py --output test-results/style-gallery
```

A ferramenta Web exporta uma cópia temporária com a galeria como cena inicial;
não altera a cena inicial do jogo. Captura os quatro estados de carta e botões nativos,
barras com previsão, foco e uma troca real para texto ampliado. Para revisão da partida:

```bash
python tools/iterate.py --label estilo --goal 'Descrever a mudança observável' --baseline <evidência-anterior> --video
```

A galeria ajuda a detectar inconsistências locais. A partida exportada verifica o
contexto real da floresta e cinco formatos, inclusive inventário com texto ampliado.
As cores, geometrias e durações padrão preservam a direção visual anterior.
