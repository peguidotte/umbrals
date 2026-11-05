# Foli lifecycle combinado com a candidata

Branch de verificação separada `integration/foli-lifecycle-check-20261105`.
Combina `81f5d43` (#20) com `f5bfc21` (#15), sem atualizar a candidata publicada
ou main. Não é promoção nem aceitação integral.

Conflitos foram resolvidos preservando o adaptador moderno de Brasa usado por
Foli, incluindo espelhamento corrigido, cache, revive e cancelamento que não
limpa KO. O UID compartilhado conserva o valor já usado pela candidata. Os
pins `characters/creature-lifecycle` (Brasa) e `characters/lifecycle-moss`
(Foli) coexistem; o pin por forma tem prioridade. O retrato novo de Foli não
retorna ao atlas antigo. Pins da casa e `world/refuge-lateral@1.1.0` são da
candidata. README de assets foi unido; os índices foram regenerados.

A primeira execução focada passou arquitetura, assets, catálogo, save,
UI flow e história do grimório. Movimento falhou em 2 de 106 verificações:
um prazo de 18 s durante feedback de Foli e a expectativa antiga de idle
imediato após o feedback do item de Brasa. A tentativa permanece em
`artifacts/harness/foli-combined-candidate-20261105T043103813385Z-172da2/`.

O revive moderno pode durar 0,6 s mais 0,12 s de transição, enquanto o
feedback curto termina antes. O teste agora conserva o assert de término
do feedback e observa o ciclo por até 1500 ms antes da asserção original de
HP vivo, ausência de KO e idle. Uma recuperação travada continua falhando.
O ajuste recebeu revisão independente somente de leitura.

O alvo movimento isolado, com `jobs=1`, passou **106 checks**, zero falhas,
em 35,885 s, com fontes iguais antes/depois. Relatório em
`artifacts/harness/foli-combined-motion-isolated-20261105T043303859997Z-63d14c/`.
O prazo de Foli e os limites do runner não mudaram. O sucesso isolado não
prova a causa do timeout concorrente. Não foram repetidos os seis alvos já
aprovados, pois o único ajuste posterior é a sincronização desse teste.

A revisão estática conferiu 66 bindings, caminhos existentes, hashes dos
dois módulos, ausência de conflitos residuais e preservação dos hooks.
Relatório em `artifacts/foli-combined-candidate-review/`. Esses resultados
não substituem a aceitação integral da combinação nem revisão visual conjunta.
Os bloqueios estéticos de Brasa e da candidata documentados no #15 continuam
abertos; os assets antigos não receberam aprovação nova por este teste.

## Acréscimo de Folife

A mesma branch combinou também `b708c91` (#21), sem conflitos adicionais.
Os índices foram regenerados preservando os pins de Foli, Folife, Brasa e
casa. O alvo combinado de movimento passou 144 checks, zero falhas, em
45,082 s, incluindo os dois ciclos das lebres e os casos de Brasa. Assets,
catálogo de assets e save também passaram. Fontes antes/depois iguais;
cobertura explicitamente focada. Evidência:
`artifacts/harness/folife-combined-candidate-20261105T044927072747Z-3a2bbb/`.

Não houve nova aceitação integral ou captura visual conjunta. A revisão
individual de Folife não encerra os bloqueios estéticos antigos da candidata.
O patch proposto para selecionar o mesmo Chromium provisionado na coleta e
nos launches do CI passou `git apply --check` nesta combinação, mas não foi
aplicado. O erro Mixed tool versions permanece bloqueio separado.
