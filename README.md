# Umbral: Ecos do Bosque

[![CI do Umbral](https://github.com/peguidotte/umbrals/actions/workflows/umbral.yml/badge.svg)](https://github.com/peguidotte/umbrals/actions/workflows/umbral.yml)

Roguelike 2D de poderes e criaturas, em português. Cada **Umbral** tem um trait da espécie, uma passiva individual e uma evolução que desbloqueia outro poder. Versão **0.3.0**, em **Godot 4.6.3 / GDScript**. O projeto tem repositório próprio: `project.godot`, código, assets, testes, skills e harness ficam na raiz.

O jogo abre em um menu na floresta. O combate tem criaturas em cena, HUD compacto, cartas em leque, previsão de consequências e impactos curtos. Pausa, grimório, inspeção e opções compartilham navegação por foco. Música, efeitos, movimento reduzido, flashes opcionais e texto ampliado ficam nas opções e persistem entre sessões.

## Jogar

- **Windows:** extraia `builds/Umbral-0.3.0-windows.zip` e execute `Umbral.exe`.
- **Linux:** extraia o bundle Linux, execute `chmod +x Umbral.x86_64` e abra o executável.
- **Web:** extraia o bundle Web, execute `python -m http.server 8000` nessa pasta e abra `http://localhost:8000`. Abrir o HTML por `file://` não funciona.
- **Godot:** importe `project.godot` e pressione F5, ou execute `godot --path .`.

Escolha **Iniciar expedição**. Clique nos poderes ou use **1–6**. **Espaço** conjura; **R** troca os selecionados; **C** inspeciona; **Esc** pausa/volta. Setas/Tab navegam e **Enter** ativa o item em foco. No controle: direcional navega, **A** seleciona, **X** conjura, **RB** troca, **Y** inspeciona e **B** volta.

Escolha até **3 poderes**, usando até **3 energia** por rodada. Leia a intenção do inimigo e combine dano, escudo e cura. A prévia mostra o fôlego resultante. Escudo dura a rodada; queimadura causa dano ao conjurar, acumulando e perdendo uma carga depois. São 3 encontros, 7 rodadas e 2 trocas por encontro.

Ao vencer, escolha uma recompensa e recupere até 8 de fôlego. **Capturar** traz um novo indivíduo com a passiva exibida. **Evoluir** preserva identidade/passiva, melhora o trait e os poderes, e desbloqueia uma assinatura. Com o time de 3 cheio, uma nova captura pede uma substituição explícita.

## Umbrals e poderes

| Espécie → evolução | Trait único | Exemplos de poderes |
|---|---|---|
| Brasa → Ignivar | Combustão: ataques aplicam queimadura | Bola de fogo, Garra de brasas, Manto de cinzas; evolução abre Sol devorador |
| Musgo → Verdálio | Raízes Vivas: proteger também cura uma vez por rodada | Chicote de espinhos, Muralha de raízes, Semente vital; evolução abre Santuário ancestral |
| Faísca → Tempestral | Circuito Vivo: ataques ganham dano por outro Umbral ativo | Arco elétrico, Véu estático, Mergulho trovão; evolução abre Juízo da tempestade |

Passivas individuais: **Feroz**, **Resiliente**, **Vital**, **Ardente** e **Ágil**. O sorteio usa pools úteis para cada espécie. Ágil reduz o custo total daquele indivíduo em 1 por rodada, independentemente de quantas cartas suas forem usadas.

Conjurar poderes de **três indivíduos diferentes** ativa Vínculo triplo (+6 dano). Os efeitos vêm dos membros atuais do time, não de números ou combinações de baralho. Trocar um Umbral remove seus poderes; evoluir melhora os existentes e adiciona a assinatura.

A primeira semente é `42013` para uma partida reproduzível. **Nova expedição** sorteia outra semente e passivas. **Repetir a mesma semente** reproduz indivíduos e sorteio; decisões diferentes ainda mudam o resultado.

## Desenvolvimento e evidências

```bash
source tools/environment.sh
python tools/iterate.py --label minha-iteracao --goal 'Melhoria observável de experiência' --video
python tools/serve.py
```

`iterate.py` executa `check.sh`, exporta Web e joga no navegador. Preserva cada tentativa em `artifacts/`, com hash das fontes, logs, relatório, capturas, snapshots, matriz de resolução e vídeo opcional. `review.html` reúne evidências e notas de avaliação. Use `--baseline <diretório-anterior>` para comparar versões. Veja `docs/iteration-harness.md`.

`check.sh` executa exemplos numéricos de traits/passivas, transições, orçamento de energia, propriedade dos poderes, conservação do deck, 100 simulações, dois testes de mutação, preferências/stack e eventos de teclado/controle na cena real. Erros do Godot e runs sem testes são rejeitados.

O harness Web joga por cliques e teclado reais. Verifica menu, opções, pausa, foco, energia, camadas, captura, evolução, assinatura, save após reload e substituição/cancelamento. Exercita cinco formatos de tela, incluindo 720p, 4:3 e ultrawide, com texto ampliado. Evidências e builds são ignorados no Git. Gates automáticos não atribuem nota de beleza ou diversão: a revisão dos renders e do vídeo registra a decisão.

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

O bootstrap usa artefatos oficiais e valida SHA-512. O download inicial de templates tem cerca de 1,26 GB; só os necessários são retidos. Veja `docs/architecture.md`, o workflow de IA em `.agents/skills/umbral/SKILL.md` e as nove skills de gamedev instaladas em `.agents/skills/`. `game-feel` e `game-ui-ux` são obrigatórias para mudanças de experiência.

## Limites

MVP com 3 espécies, 3 evoluções, 12 poderes e 5 passivas; a run continua curta. O bot heurístico usa dano, escudo e cura, mas simulações não comprovam diversão nem balanceamento final. Criaturas/poderes são vetores originais; a floresta foi gerada com Image Gen; música ambiente e efeitos usam síntese original. Não há mapa ramificado, loja, remapeamento de controles, save de uma run em andamento ou Steamworks. Apenas preferências e estatísticas são salvas.

O build Windows é exportado sem assinatura e precisa de playtest em Windows. Navegação por controle tem teste com eventos Godot simulados; falta controle físico. O render Web é validado com Chromium/software WebGL; performance e áudio em hardware real ainda exigem avaliação. Consulte o badge e a execução correspondente ao commit para verificar o resultado remoto do CI.
