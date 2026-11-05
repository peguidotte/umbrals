# Foli → Folife → Foslash: catálogo revisado por expedição

O nome da linhagem aprovado por Pedro é **Foli → Folife → Foslash / Folivel**.
Esta fatia torna Foslash uma escolha explícita após Folife nas novas runs.
O ID da espécie continua `moss`; as formas continuam `moss` e `verdalio`, e a
aresta continua `moss_to_verdalio`. Assim, descobertas, indivíduos e saves
existentes usam os mesmos registros. A nova forma é `foslash`, com aresta
`verdalio_to_foslash` e arte lógica `umbrals/foslash`. Não há estágio ordinal.

Os atributos provisórios de Foslash repetem apenas o avanço numérico já usado
de Foli para Folife: HP 72, ataque 14, defesa 6, velocidade 12 antes da passiva;
`living_roots` com valor 6; perfil de poderes com dano 10, escudo 8, cura 4,
queimadura 2 e Encharcado 2. Natureza Bosque e resistência de 25% permanecem.
Esse delta melhora as mesmas cópias existentes e não representa balanceamento
final aprovado. Não há novos poderes mecânicos, cópias gratuitas ou assinatura
concedida automaticamente; UID, passiva e cópias existentes persistem, com HP
proporcional ao novo máximo. O ajuste afeta só a forma acessível às novas runs
de catálogo 1; as runs históricas de catálogo 0 conservam os valores anteriores.

`expedition-rules-4` grava `catalog_revision` separado de `event_revision`.
Runs antigas migram para catálogo 0, mantendo suas ofertas e comandos anteriores;
novas runs usam catálogo 1 e podem escolher Foslash na recompensa da Mata fechada
após terem escolhido Folife na Clareira. Reabrir uma run não libera a nova aresta
silenciosamente. Geração, escolha e restore aplicam a mesma revisão; identidades
e revisões desconhecidas falham sem substituir o save. Veja
[compatibilidade](../../../docs/save-format.md).

Folivel (furtivo, folhagem cortante nos quatro membros, capaz de crescer e
encolher) é nome/conceito aprovado, ainda sem forma jogável nesta fatia. Sua
integração deve ser um commit posterior com catálogo 2 e manifesto congelado da
revisão 1, preservando também as runs de Foslash já iniciadas.

## Arte atual desta branch

Foli e Folife possuem pilotos próprios fixados por `umbrals/moss` e
`umbrals/verdalio`, com caminhada/KO versionados separadamente. Foslash usa
`umbrals/foslash`; a integração visual e suas evidências são responsabilidade
do integrador e não são comprovadas pelos testes de catálogo/save.

As duas referências antes bloqueadas foram materializadas e inspecionadas
neste executor. Originais: [referências](../../../docs/references/creatures/foli/README.md).
O [escopo do primeiro piloto](../../../docs/foli-pilot-v05-art-02f.md) é histórico;
não comprova o estado completo desta fatia. Arte/fluidez ainda exigem revisão
visual independente. Os testes de compatibilidade usam uma run anterior real,
sem transformar sua aprovação técnica em aprovação estética ou de balanceamento.
