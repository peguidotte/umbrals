# Autoria de espécies e formas

Antes de escrever histórias ou descrições, leia [lore e status das decisões](lore/README.md)
e a [conciliação com o conteúdo atual](lore/implementacao.md). Texto exploratório
não confirma cosmologia, região ou origem das cartas; preservar regras e saves.

Cada linhagem fica em `content/species/<species_id>/species.tres`. IDs são
estáveis, minúsculos e usam letras ASCII, dígitos e sublinhado. IDs de formas
são globalmente únicos entre espécies para a descoberta no códex. Indivíduos guardam
`species` e `form_id`; a ordem das formas não define mecânicas. Os arrays de
formas e transições têm ordem explícita. Uma forma pode ter várias saídas e
cada transição tem seu próprio ID, origem e destino.

`python tools/umbrals.py author <id> --fallback ember` cria um pacote inicial
com dados e arte da forma escolhida como fallback explícito. Revise nome,
atributos, naturezas, resistências, trait_id e valor, história (título e texto), poderes iniciais, assinatura, passivas, perfil dos poderes e arte;
o comando não cria imagens. O comando acrescenta o pacote ao manifesto ordenado `content/species/catalog.tres`. Os bindings de arte devem existir
em `assets/runtime-lock.json`; não copie nem altere releases imutáveis. Arte nova
segue o processo e versionamento de `docs/assets/README.md`.

Cada forma declara todos os atributos e um perfil de incrementos para dano,
escudo, cura, queimadura e Encharcado. Incrementos só se aplicam quando o poder
já possui o efeito correspondente, inclusive poderes aprendidos depois do início.
Traços usam um ID de comportamento registrado nas regras e um valor por forma.
Evoluir altera a forma e melhora poderes existentes; não cria cartas de assinatura.

Execute `python tools/umbrals.py validate`, `python tests/catalog_authoring_test.py`
e `godot --headless --path . --script tests/catalog_test.gd`, além dos gates do
harness relevantes. O validador verifica IDs, campos, trait registrado, arestas, ausência de ciclos,
alcance desde a forma inicial e bindings fixados;
revisão de balanceamento, comportamento registrado e arte continua necessária.
A tabela `LEGACY_FORMS` é apenas para migração de saves schema 1 e adaptadores
antigos; novas formas não devem depender de números de estágio.

Os READMEs de cada pacote registram versões e a cobertura real de arte. O fallback
portável atual usa retratos estáticos com movimento de apresentação, sem alegar
clips direcionais que ainda não existem. `python tools/assets.py validate` valida
os contratos e integridade dos releases; novas animações exigem revisão própria.

IDs de forma também não podem coincidir com os IDs de descoberta dos encontros
(derivados do basename da arte dos inimigos em `ENCOUNTERS`); o validador consulta
esse catálogo para reservar os IDs. A descoberta registra a forma inicial e a
forma observada, sem interpretar o ID da espécie como ID de outra forma.

## Poderes, consumíveis e encontros

Os catálogos ordenados em `content/powers/`, `content/items/` e
`content/encounters/` usam um recurso por ID estável. Para iniciar um novo
registro com valores explícitos de outro, execute, por exemplo,
`python tools/content_authoring.py author powers novo_poder --fallback fireball`.
Revise todos os campos, texto e arte fixada antes de usá-lo. O comando não cria
arte. `python tools/content_authoring.py validate` verifica os manifestos,
referências, valores e comportamentos conhecidos; execute também
`python tools/umbrals.py validate` e os testes de catálogo.

Consumíveis declaram `effect_id` e os valores em `effect_parameters`: os comportamentos `heal` e `revive` são
registrados em `scripts/battle/item_effects/registry.gd`. Novos comportamentos
precisam de um handler puro e de uma entrada em `PARAMETER_SCHEMAS` no registro, para validar os parâmetros de autoria. Encontros adicionais não
alteram automaticamente a rota existente: a lista de IDs da rota é explícita.
`gameplay_catalog.gd` constrói snapshots isolados e seus métodos devolvem cópias;
os testes, passe manifestos próprios em vez de alterar o catálogo de produção.
Descrições e história são apresentação e ficam fora da identidade de gameplay.

New edges on an existing lineage may declare `deferred: true` when an audited
compatibility migration requires new choices to follow all historical reward
choices. This flag changes offer ordering across the party, not edge eligibility
or progression stage. It must be boolean. Do not apply it retroactively to an
old edge; follow the explicit compatibility process in `docs/save-format.md`.
