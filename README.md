# Umbral: Ecos do Bosque

[![CI do Umbral](https://github.com/peguidotte/umbrals/actions/workflows/umbral.yml/badge.svg)](https://github.com/peguidotte/umbrals/actions/workflows/umbral.yml)

Roguelike 2D de poderes e criaturas, em português. Cada **Umbral** tem um trait da espécie, uma passiva individual e uma evolução que melhora seus atributos e poderes conhecidos. Versão **0.3.0**, em **Godot 4.6.3 / GDScript**. O projeto tem repositório próprio: `project.godot`, código, assets, testes, skills e harness ficam na raiz.

O [roadmap até a Steam 1.0](docs/roadmap.md) define visão, batalha, catálogo, critérios por versão e o protocolo de cada iteração. Abra também o [mapa visual interativo](docs/roadmap.html), que funciona offline sem imagens externas.

A estrutura do MVP de batalha está fechada tecnicamente em V04-BAT-04A/B. A [primeira expedição com mapa e escolhas de rota](docs/expedition-implementation-v0.5.md) está integrada com save/continuar, validada localmente. Fluxo, mapa e save foram desenvolvidos em paralelo após fixar o contrato. UX/playtests da batalha continuam em paralelo, sem declarar o marco 0.4 concluído.

O [formato visual do MVP de batalha](docs/references/battle/00-aprovada/README.md) foi aprovado: horizontal elevada, grupos quase alinhados e HUD em quatro zonas. As 41 imagens de referência estão no [acervo organizado](docs/references/battle/README.md), com [galeria local](docs/references/battle/index.html). As decisões da [entrevista](docs/battle-interview-next.md) orientam a [primeira implementação coletiva](docs/battle-implementation-v0.4.md), já jogável e validada localmente neste checkout. A versão permanece 0.3.0 enquanto os critérios do marco 0.4 não forem cumpridos. A [revisão de fundo e apoio dos sprites](docs/visual-review-depth-v0.4.md) incorpora o feedback visual mais recente.

O jogo abre em um menu na floresta. O combate tem criaturas em cena, HUD compacto, cartas em uma faixa inferior, previsão de consequências e impactos curtos. Pausa, grimório, inspeção e opções compartilham navegação por foco. Música, efeitos, movimento reduzido, flashes opcionais e texto ampliado ficam nas opções e persistem entre sessões.

## Jogar

- **Windows:** extraia `builds/Umbral-0.3.0-windows.zip` e execute `Umbral.exe`.
- **Linux:** extraia o bundle Linux, execute `chmod +x Umbral.x86_64` e abra o executável.
- **Web:** extraia o bundle Web, execute `python -m http.server 8000` nessa pasta e abra `http://localhost:8000`. Abrir o HTML por `file://` não funciona.
- **Godot:** importe `project.godot` e pressione F5, ou execute `godot --path .`.

Escolha **Iniciar expedição** e seu primeiro vínculo: Brasa, Musgo, Faísca ou Orvalho. No mapa, selecione um caminho e confirme. A Clareira leva à Mata fechada (combate/recompensa) ou à Nascente (cura limitada), e depois ao Guardião. **Continuar expedição** retoma o último estado confirmado. **Treino de batalha** mantém o percurso curto anterior sem sobrescrever a expedição salva. Clique nos poderes ou use **1–6**. **Espaço** conjura; **R** resortear passa a rodada inteira; **C** inspeciona; **Esc** pausa/volta. Setas/Tab navegam e **Enter** ativa o item em foco. No controle: direcional navega, **A** seleciona, **X** conjura, **RB** resortear, **Y** inspeciona e **B** volta.

Comece com **um Umbral**, até **três ativos por escolha** e **seis integrantes no time**. A mão base tem **seis cartas**; há **três ações compartilhadas**, com custos por poder, troca ou consumível. Cada indivíduo tem HP, Ataque, Defesa e Velocidade. Aliados e adversários atuam por velocidade e prioridades explícitas. Selecione uma carta e clique no alvo; poderes podem atingir superior + central, central + inferior, todos ou uma vaga individual, sem retaguarda.

**Conjurar** confirma o plano. Trocas/entradas custam uma ação, não acontecem ao clicar na reserva e não compram cartas imediatamente. O substituto recebe ataques naquela vaga. Cartas de reservas aptos ficam fora da compra; cartas de incapacitados continuam bloqueadas no ciclo. Usadas ou não, as cartas da mão vão ao descarte ao fim da rodada; ele só é reembaralhado quando a compra acaba.

**Resortear** passa o turno e deixa o inimigo agir. A mochila contém poções e reanimação, com custo de uma ação; consultar é gratuito. Reanimados agem na próxima rodada. Reposição após nocaute é gratuita depois da fila completa. A informação inimiga tem três modos sobre o mesmo plano: parcial por padrão, oculto e completo; mudanças durante o combate valem na próxima rodada.

Ao vencer, **Capturar** permite escolher uma vaga livre no campo ou a reserva, com a passiva exibida. Capturar no campo entre encontros não custa ação. **Evoluir** preserva UID/passiva e as mesmas cópias, melhorando atributos e poderes sem acrescentar cartas automaticamente. Entre encontros é possível ajustar a formação. Um time cheio exige escolher quem sai. O treino tem três encontros de protótipo, com um, dois e três adversários; não há derrota por um limite artificial de sete rodadas.

## Umbrals e poderes

| Espécie → evolução | Trait único | Exemplos de poderes |
|---|---|---|
| Brasa → Ignivar | Combustão: ataques aplicam queimadura | Bola de fogo, Garra de brasas, Manto de cinzas; Sol devorador é técnica de linhagem |
| Musgo → Verdálio | Raízes Vivas: proteger também cura uma vez por rodada | Chicote de espinhos, Muralha de raízes, Semeadura; Santuário ancestral é técnica de linhagem |
| Faísca → Tempestral | Circuito Vivo: ataques ganham dano por outro Umbral ativo | Arco elétrico, Interferência, Mergulho trovão; Juízo da tempestade é técnica de linhagem |
| Orvalho → Marevéu | Maré Marcada: água deixa Encharcado | Jato de orvalho, Chuva lateral, Gota serena |

Passivas individuais: **Feroz**, **Resiliente**, **Vital**, **Ardente** e **Ágil**. O sorteio usa pools úteis para cada espécie. Ágil concede +3 Velocidade ao indivíduo. Os números do catálogo são valores iniciais de protótipo.

As combinações vêm dos efeitos e da ordem de execução: água antes de raio permite dano ampliado contra Encharcado. Uma iniciativa diferente pode desfazer essa sequência; clicar primeiro não antecipa uma técnica. Assinaturas têm dados de catálogo, mas a loja/aprendizado ainda são trabalho posterior.

A primeira semente é `42013` para uma partida reproduzível. **Nova expedição** sorteia outra semente e passivas. **Repetir a mesma semente** reproduz indivíduos e sorteio; decisões diferentes ainda mudam o resultado.

## Desenvolvimento e evidências

```bash
source tools/environment.sh
python tools/iterate.py --label minha-iteracao --goal 'Melhoria observável de experiência' --video
python tools/serve.py
```

`iterate.py` executa `check.sh`, exporta Web e joga no navegador. Preserva cada tentativa em `artifacts/`, com hash das fontes, logs, relatório, capturas, snapshots, matriz de resolução e vídeo opcional. `review.html` reúne evidências e notas de avaliação. Use `--baseline <diretório-anterior>` para comparar versões. Veja `docs/iteration-harness.md`.

`check.sh` executa exemplos numéricos de traits/passivas, transições, orçamento de ações, propriedade dos poderes, conservação do deck, 100 simulações, oito testes de mutação, preferências/stack e eventos de teclado/controle na cena real. Erros do Godot e runs sem testes são rejeitados.

O harness Web joga por cliques e teclado reais. Verifica menu, opções, pausa, foco, ações, camadas, alvos, captura, evolução, entrada de reservas, preferências/estatísticas após reload e cancelamentos. A liberação de um time cheio é coberta separadamente por fixture numérica. Exercita cinco formatos de tela, incluindo 720p, 4:3 e ultrawide, com texto ampliado. Evidências e builds são ignorados no Git. Gates automáticos não atribuem nota de beleza ou diversão: a revisão dos renders e do vídeo registra a decisão.

O [CI](docs/ci.md) apresenta resultados no resumo da execução, preserva evidências de falhas e entrega os bundles Web, Windows e Linux como artifacts. Inclui regressão de recarga rápida das preferências e smoke test do executável Linux.

Se as ferramentas não estiverem disponíveis, no Linux x86_64:

```bash
source tools/environment.sh
python tools/install_godot.py
python -m pip install -r tools/requirements-browser.txt
python -m playwright install chromium
bash tools/build.sh Windows
bash tools/build.sh Linux
python tools/package.py
```

O bootstrap usa artefatos oficiais e valida SHA-512. O download inicial de templates tem cerca de 1,26 GB; só os necessários são retidos. Veja `docs/architecture.md`, o workflow de IA em `.agents/skills/umbral/SKILL.md` e as nove skills de gamedev instaladas em `.agents/skills/`. A skill local [umbral-design-interview](.agents/skills/umbral-design-interview/SKILL.md) orienta o planejamento por blocos de perguntas com opções e recomendações fundamentadas. `game-feel` e `game-ui-ux` são obrigatórias para mudanças de experiência.

## Limites

Protótipo coletivo com 4 espécies, 4 evoluções, 18 poderes de catálogo (12 iniciais) e 5 passivas; a run continua curta. O bot heurístico usa dano, escudo e cura, mas simulações não comprovam diversão nem balanceamento final. Criaturas usam atlas original em pixel art e fallback vetorial; ícones dos poderes são vetores originais; a floresta foi gerada com Image Gen; música ambiente e efeitos usam síntese original. A expedição tem uma bifurcação fixa e checkpoint versionado; geração procedural ampla, loja, eventos variados, relíquias adquiríveis, remapeamento de controles e Steamworks seguem futuros. Preferências/estatísticas ficam separadas da run salva.

O build Windows é exportado sem assinatura e precisa de playtest em Windows. Navegação por controle tem teste com eventos Godot simulados; falta controle físico. O render Web é validado com Chromium/software WebGL; performance e áudio em hardware real ainda exigem avaliação. Consulte o badge e a execução correspondente ao commit para verificar o resultado remoto do CI.

A [revisão tática da batalha](docs/battle-tactics-review-v0.4.md) documenta o plano editável (P/LB), alvos por Q/E, consulta de pilhas e o ajuste de desafio/arquitetura.

A [fatia de naturezas e reações](docs/natures-status-reactions-v0.4.md) acrescenta
resistências explícitas e natureza por golpe. **Semeado + Bosque/Água/Fogo**
concede escudo/cura/Queima; **Interferência** reduz em 25% o próximo ataque,
sem remover ações. **Encharcado + Raio** continua dobrando potência. A inspeção
explica duração/fonte e resistências; os números são de protótipo. Tempestral
possui Raio/Água, sem cartas ou resistências extras automáticas.

A validação local da fatia elemental e os limites de playtest estão na
[especificação](docs/natures-status-reactions-v0.4.md#validação-local-de-v04-bat-03a).

A [revisão de captura, circulação e leitura da rodada](docs/battle-closeout-v0.4.md)
acrescenta a faixa de comandos, RESUMO da última rodada, detalhes por toque e
reinserção de reservas sem blocos por dono. PLANO também permite conjurar.
