# Família elétrica — Nisca → Niscor → Auravel / Zuldar

Pedro aprovou essa família e a referência
`libfile_2b00aa3086e48191af8247acac969990` /
`familia-eletrica-rostos-pelos-azuis-v10.png`. O PR #13 (`06806eb`) integrou
nomes e histórias com arte anterior. V05-ART-02 materializou e inspecionou a
referência neste executor e criou sprites novos de Nisca e Niscor.

Bindings estáveis `umbrals/volt` e `umbrals/tempestral` propõem
`characters/electric-family@2.0.0`, papéis `nisca-ally` e `niscor-ally`.
O módulo contém a vista oposta, apoio no chão, curvas corporais próprias,
idle, passada, dano, KO e pontos de ataque nos espinhos/crista/patas.
Niscor conserva alguns pelos azuis, sem agulhas suspensas. Animações usam
malhas sobre sprites novos, não frames redesenhados.

IDs de espécie, formas, descoberta e aresta `volt_to_tempestral` permanecem.
Atributos e naturezas das duas formas existentes permanecem; novas formas têm defaults explícitos.
Sprites antigos e seus releases permanecem imutáveis para rastreabilidade.

Auravel alado e Zuldar bípede com espinhos azuis recebem pins próprios em
`characters/electric-adults@2.0.0`, com rigs, estados, sockets e arestas jogáveis
`tempestral_to_auravel` / `tempestral_to_zuldar`. As candidatas 1.0.0 ficam
imutáveis. Novos stats são defaults de protótipo por delegação, não números
aprovados como balanceamento final. [Implementação e migração](../../../docs/electric-adults-v05-art03.md).

A continuação propõe Nisca/Niscor em 2.1.0: corrige a origem secundária do
Niscor para um espinho visível nas duas vistas. Saves antigos conservam seus
comandos por migração auditada e ordenação das novas ofertas ao final.

O rascunho parte do PR #13 e não faz merge. O integrador revisa os dois pins
e reconcilia os índices gerados. `main.gd`, Rules, registro e baseline não mudam.
[Proveniência, limites e validação](../../../docs/electric-family-v05-art02.md).
