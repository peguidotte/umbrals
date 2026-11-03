# Autoria de espécies e formas

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
