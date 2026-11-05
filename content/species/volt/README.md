# Nisca e Niscor: integração de nomes, arte anterior preservada

Pedro aprovou a família **Nisca → Niscor → Auravel / Zuldar**. Esta primeira
fatia altera somente apresentação: `volt` passa a exibir Nisca e `tempestral`
passa a exibir Niscor. IDs de espécie, formas, descoberta e da aresta
`volt_to_tempestral` continuam estáveis. Atributos, naturezas, poderes, passivas,
cópias, regras e compatibilidade de saves não mudam.

Os textos de Nisca/Niscor e de Juízo da tempestade usam os nomes aprovados.
Niscor tem alguns pelos azuis; não ganha agulhas destacadas controladas à distância.
Novos projéteis e variações dos adultos ainda precisam de uma fatia de conteúdo
e balanceamento. Auravel (alado) e Zuldar (bípede, espinhos azuis carregados)
estão aprovados como direção, mas ainda não são formas jogáveis neste catálogo.

## Referência aprovada e bloqueio

Library `libfile_2b00aa3086e48191af8247acac969990`, arquivo
`familia-eletrica-rostos-pelos-azuis-v10.png`. A materialização com os helpers
atuais da skill Library falhou em 05/11/2026 com
`library file transfer failed: download failed`. Não há pixels locais legíveis
dessa referência; nenhuma arte nova foi criada, copiada ou validada.

Os retratos e atlas atuais continuam sendo a representação anterior da família,
e **não são sprites finalizados de Nisca/Niscor/Auravel/Zuldar**. A entrega é
de nomes/descrições no fluxo jogável atual, não de produção de arte aprovada.

## Arte fixada

O Resource da linhagem referencia os seguintes bindings de produção:

- `volt`: `umbrals/volt` → `assets/umbrals/volt/versions/1.0.0/manifest.json`, papel `portrait`.
- `tempestral`: `umbrals/tempestral` → `assets/umbrals/tempestral/versions/1.0.0/manifest.json`, papel `portrait`.

Estes releases são retratos estáticos: o runtime usa a mesma imagem em ambos os
lados e anima movimento, idle, ataque e defesa por transformações de apresentação.
Eles não declaram sprites direcionais ou clips de animação próprios. Caso um
conjunto animado seja criado, registre ambos os lados e os clips necessários
no release versionado, fixe-o no runtime-lock e valide pelo pipeline de assets.
Nenhuma arte é copiada para este pacote.

## Continuação para o integrador

1. Obter a referência pelo fluxo suportado e inspecionar os pixels localmente.
2. Produzir primeiro Nisca com os dois lados, idle, movimento, dano, KO e origens
   de ataque verificadas no jogo. Criar release imutável e só então propor o pin
   ao editor de `assets/runtime-lock.json`.
3. Repetir para Niscor. Preservar os IDs existentes e o digest de gameplay se a
   mudança continuar cosmética; não reutilizar a coreografia de carapaça/antenas
   como se tivesse sido aprovada para o novo corpo.
4. Integrar Auravel e Zuldar por arestas explícitas a partir de Niscor, com stats,
   poderes e migração revisados antes de torná-los elegíveis. Não inferir os
   novos atributos, naturezas ou ataques a partir do desenho.

Esta branch não edita `main.gd`, `rules.gd`, o registro do harness, a baseline
arquitetural ou `runtime-lock.json`; esses pontos continuam com o integrador.
