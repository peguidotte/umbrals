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
