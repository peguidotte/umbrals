# V05-BAT-10 — companheira de Lonelo no combate

Base: main `8d1a3ae` (PR #32 integrado). Pequena implementação da direção
confirmada: esfera com vida própria, dependente de Lonelo, capaz de atacar junto.
Arte permanece estudo procedural; nenhum asset foi alterado ou aprovado aqui.

## Regra provisória

Em novas expedições (ruleset 5, catálogo 6), cada técnica ofensiva de água de
**alvo único** de Lonelo produz um segundo golpe no mesmo alvo sobrevivente.
A companheira usa potência fixa **6**, sem bônus de ataque, passiva ou Carga.
Eletrificado reduz a potência dos dois golpes; defesa, resistência à água e
escudo são processados separadamente. Não repete Encharcado, Queima nem reações.

O segundo golpe acontece imediatamente após os efeitos do primeiro, dentro da
mesma técnica/iniciativa: não adiciona carta, ação, unidade, turno ou sorteio.
Se o primeiro golpe matar, não há segundo golpe nem troca automática de alvo.
Se Lonelo estiver incapacitado, na reserva ou aguardando a rodada após reviver,
a técnica e a companheira não agem. Duas cópias distintas da técnica podem
produzir dois pares de golpes, pagando os custos normais de cada cópia.

Áreas e suporte não disparam a companheira nesta fatia. A regra vale também
para um Lonelo adversário usando uma técnica compatível. Nenhuma outra forma
ou família recebe o comportamento. Potência 6, restrição a alvo único e ausência
de reaplicação de condições são **escolhas provisórias de balanceamento**, não
novas decisões definitivas do usuário.

## Informação e apresentação

Tooltip da carta e bônus do preview explicam o segundo golpe; potência agregada
é potencial antes de defesa/resistência, não previsão exata de HP. Preview não
altera RNG/estado. Os dois eventos carregam snapshots separados de HP/escudo.
O segundo aparece como “Companheira de Lonelo” no resumo e usa uma segunda
conjuração visual pelo sistema existente. A animação ainda reutiliza os gestos
aquáticos; não há direção de ataque corporal exclusiva ou autonomia visual
finalizada. A esfera não possui HP próprio ou seleção independente.

## Compatibilidade e validação

`aquatic5_manifest.gd` e `aquatic5_lonelo_8d1a3ae.json` foram capturados da main
antes de mudar regras. Saves de catálogo 0–5 mantêm um golpe; migração troca a
identidade de destino e preserva a revisão. Histórico com marcador 6 forjado é
rejeitado. Replay histórico compara snapshots e eventos completos, não apenas
HP. Novo replay faz save/load real e compara estado e eventos após comandos.

Foco congelado `artifacts/harness/lonelo-companion-frozen-20261105T180209488537Z-56672c/harness-run.json`: passou em 84,145 s, fontes/inputs verificados. Regras: 14.321 checks; saves: 531; movimento: 1.012; fixtures: 66; migração: 5; arquitetura: 142 módulos; export Web passou.

Gravação `artifacts/lonelo-companion-combat-20261105/lonelo.mp4`: três cartas conjuradas por inputs reais, áudio do próprio jogo, nenhum erro de navegador. O campo legado `performances` do capturador conta cartas (3), não gestos; o teste nativo confirma dois gestos por uma carta. Frame extraído em 4,5 s foi inspecionado e mostra “Companheira de Lonelo” com o segundo dano. Arte e escala permanecem provisórias. GitHub Actions segue
desativado. Não há merge sem revisão independente e regressão de integração.

## Correção da prévia na integração

A revisão reproduziu valores inconsistentes com duas cópias de Jato de orvalho:
com Carga 8, a prévia indicava 74 e a resolução sem defesas aplicava 66;
com Eletrificado, indicava 42 em vez de 50; com ambos, 54 em vez de 56.
O teste de regressão foi executado antes da correção e registrou três falhas.

No grafo 6, `PowerEvaluation.evaluate` ordena somente as próprias técnicas com o
comparador canônico de iniciativa e avalia cópias destacadas dos donos. Carga
e Eletrificado são consumidos nessa cópia no primeiro ataque, como na resolução.
A potência da companheira e a do golpe original são somadas no mesmo passe,
com a mesma amostra de modificadores. Não resolve planos inimigos, não revela
informação oculta e não altera estado ou RNG. O valor continua sendo potência
condicional antes de defesas/resistência, não previsão exata de HP: a companheira
depende da sobrevivência do alvo e do dono durante a resolução real.

| Prévia de duas cópias | Grafo 5, histórico | Grafo 6, corrigido |
| --- | ---: | ---: |
| Sem modificadores | 46 | 58 |
| Carga 8 | 62 | 66 |
| Eletrificado | 34 | 50 |
| Carga 8 e Eletrificado | 46 | 56 |

O foco da integração passou: regras 14.321, movimento 1.012, migração 5,
fixtures 66 e arquitetura; a extensão de saves passou 559 verificações,
incluindo os dois grafos, ordem inversa dos cliques e imutabilidade da origem.
O comportamento aplicado e os campos históricos de `last_result` dos saves
0–5 são preservados. Como a potência prevista também é persistida nesse
relatório, a correção sequencial fica na revisão 6. A coluna histórica acima
replica o erro antigo deliberadamente; a resolução sem defesas daquele grafo
continua aplicando 46/54/40/46 nos quatro casos. A fixture
`tests/fixtures/lonelo_preview_graph5_8d1a3ae.json` foi produzida executando o
módulo `PowerEvaluation` exato da main, verificado por SHA e contra o mesmo
manifesto mecânico. O teste compara todos os seus campos, sem reescrevê-los.

A primeira execução integral da integração foi interrompida em 261,916 s ao
identificar esse vínculo entre preview e relatório persistido. Seus relatórios
e vídeos foram preservados; ela não é aceite do conjunto.

O gate integral da revisão congelada é registrado em
`artifacts/lonelo-companion-integration/full-proof.json`; status, SHA e hashes
identificam o aceite efetivo. O foco acima não substitui a regressão integral.
Arte, potência 6 e restrições continuam provisórias; produto 0.3.0 e Actions
pausado. `AGENTS.md` registra a autorização persistente do dono para operações
do Umbral. A autorização não dispensa validação, proteção de branch ou
respeito a recusas.

## Regressão do retorno no grimório

O gate integral da candidata `28aeebe` encontrou foco vazio ao voltar de um
poder para seu link de origem. `Codex._restore_context` aguardava dois frames
antes de restaurar tanto rolagem quanto foco. Isso deixava o teclado sem dono
nesse intervalo e podia roubar um Tab posterior quando o callback concluía.

O Back agora restaura o foco sincronamente após reconstruir o registro. Apenas
a rolagem aguarda o layout, cancelando a restauração se uma navegação ou foco
mais recente tiver ocorrido. O teste nativo acrescenta Back imediato e Tab
rápido; passou 91 verificações de grimório e 437 de fluxo de UI. O cenário Web
original foi mantido e passou suas 156 verificações, sem novas esperas,
timeouts, retries ou remoção de asserções. Saves, conhecimento e RNG permanecem
inalterados. A tentativa integral com a falha foi preservada, interrompida em
2495,597 s e não é aceite; a revisão final recebe seu próprio gate congelado.
