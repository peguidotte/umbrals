# Família elétrica — Nisca → Niscor → Auravel / Zuldar

Pedro aprovou essa família e a referência
`libfile_2b00aa3086e48191af8247acac969990` /
`familia-eletrica-rostos-pelos-azuis-v10.png`. O PR #13 (`06806eb`) integrou
nomes e histórias com arte anterior. V05-ART-02 materializou e inspecionou a
referência neste executor e criou sprites novos de Nisca e Niscor.

Bindings estáveis `umbrals/volt` e `umbrals/tempestral` propõem
`characters/electric-family@1.0.0`, papéis `nisca-ally` e `niscor-ally`.
O módulo contém a vista oposta, apoio no chão, curvas corporais próprias,
idle, passada, dano, KO e pontos de ataque nos espinhos/crista/patas.
Niscor conserva alguns pelos azuis, sem agulhas suspensas. Animações usam
malhas sobre sprites novos, não frames redesenhados.

IDs de espécie, formas, descoberta e aresta `volt_to_tempestral` permanecem.
Atributos, naturezas, poderes, passivas, cópias e saves não mudam.
Sprites antigos e seus releases permanecem imutáveis para rastreabilidade.

Auravel alado e Zuldar bípede com espinhos azuis têm candidatas de corpo
nos dois lados em `characters/electric-adults@1.0.0`, prototype, sem pin.
Não são formas jogáveis. Faltam rigs, estados, sockets, arestas explícitas,
stats/poderes revisados e decisão de compatibilidade do catálogo.

O rascunho parte do PR #13 e não faz merge. O integrador revisa os dois pins
e reconcilia os índices gerados. `main.gd`, Rules, registro e baseline não mudam.
[Proveniência, limites e validação](../../../docs/electric-family-v05-art02.md).
