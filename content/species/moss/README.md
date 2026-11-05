# Foli → Folife → Foslash / Folivel: catálogo por expedição

O nome da linhagem aprovado por Pedro é **Foli → Folife → Foslash / Folivel**.
As novas runs podem escolher Foslash ou Folivel explicitamente após Folife.
O ID da espécie continua `moss`; as formas continuam `moss` e `verdalio`, e a
aresta continua `moss_to_verdalio`. Assim, descobertas, indivíduos e saves
existentes usam os mesmos registros. A nova forma é `foslash`, com aresta
`verdalio_to_foslash` e arte lógica `umbrals/foslash`. Folivel usa `folivel`,
`verdalio_to_folivel` e `umbrals/folivel`. As duas arestas partem de `verdalio`;
uma forma final não evolui para a outra. Não há estágio ordinal.

Os atributos provisórios de Foslash repetem apenas o avanço numérico já usado
de Foli para Folife: HP 72, ataque 14, defesa 6, velocidade 12 antes da passiva;
`living_roots` com valor 6; perfil de poderes com dano 10, escudo 8, cura 4,
queimadura 2 e Encharcado 2. Natureza Bosque e resistência de 25% permanecem.
Esse delta melhora as mesmas cópias existentes e não representa balanceamento
final aprovado. Não há novos poderes mecânicos, cópias gratuitas ou assinatura
concedida automaticamente; UID, passiva e cópias existentes persistem, com HP
proporcional ao novo máximo. O ajuste afeta só a forma acessível às novas runs
de catálogo 1 ou 2; as runs históricas de catálogo 0 conservam os valores anteriores.
Folivel começa com os mesmos números provisórios, natureza, resistência, traço
e perfil de Foslash, sem especialização mecânica canônica inventada. Sua direção
aprovada é a folhagem cortante nos quatro membros e a variação das folhas dos braços.

`expedition-rules-4` grava `catalog_revision` separado de `event_revision`.
Runs anteriores a Foslash migram para catálogo 0; runs da identidade congelada
`07942959…8442` mantêm o catálogo 0 ou 1 já salvo, com Foslash disponível apenas
na revisão 1. Novas runs usam catálogo 2 e podem escolher uma das duas finais
na recompensa da Mata fechada após terem escolhido Folife na Clareira.
Reabrir uma run não libera a nova aresta silenciosamente. Geração, escolha e
restore aplicam a mesma revisão; identidades e revisões desconhecidas falham
sem substituir o save. A identidade anterior não pode declarar catálogo 2,
mesmo sem uma unidade final. Veja
[compatibilidade](../../../docs/save-format.md).

## Arte atual desta branch

Foli e Folife possuem pilotos próprios fixados por `umbrals/moss` e
`umbrals/verdalio`, com caminhada/KO versionados separadamente. As finais usam
`umbrals/foslash` e `umbrals/folivel`; a integração visual e suas evidências são responsabilidade
do integrador e não são comprovadas pelos testes de catálogo/save.

As duas referências antes bloqueadas foram materializadas e inspecionadas
neste executor. Originais: [referências](../../../docs/references/creatures/foli/README.md).
O [escopo do primeiro piloto](../../../docs/foli-pilot-v05-art-02f.md) é histórico;
não comprova o estado completo desta fatia. Arte/fluidez ainda exigem revisão
visual independente. Os testes de compatibilidade usam uma run anterior real,
sem transformar sua aprovação técnica em aprovação estética ou de balanceamento.
