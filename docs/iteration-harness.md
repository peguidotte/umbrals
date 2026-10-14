# Iteração de experiência

O ciclo é **objetivo → implementação → verificações → jogar no navegador → comparar renders → registrar decisão**. As skills obrigatórias `game-ui-ux` e `game-feel` ficam em `.agents/skills/` dentro do jogo. Há também skills de Godot UI/animação/áudio, input, card-game, criação de assets e áudio. `skills-lock.json` registra origem e hashes do pacote solicitado pelo usuário.

```bash
source tools/environment.sh
python tools/iterate.py --label ui-v03 \
  --goal 'Menu de jogo, arena legível e impactos breves' \
  --baseline test-results/baseline-v0.2 --video
```

Cada tentativa cria `artifacts/<nome>-<timestamp UTC>/`, sem sobrescrever anteriores. O diretório guarda hash das fontes, versões das ferramentas, lock das skills, logs com códigos de saída, resultados de regras/mutações/input, plano de jogadas, screenshots com snapshots de estado, matriz de tela e vídeo opcional. `review.html` incorpora as capturas e os relatórios JSON: baixe o arquivo e abra no navegador, mesmo sem as pastas do projeto. Clique nas imagens para ampliar ou baixar o PNG original. O arquivo pode ser grande porque preserva os bytes das capturas.

`review-standalone.html` é uma cópia portátil com nome próprio para compartilhar. `review-bundle.zip` contém a versão completa, com vídeo e evidências originais. Extraia o ZIP e abra `index.html`, preservando as pastas extraídas. `review-delivery.json` registra tamanho, formato, origem e checksum do pacote. Para a próxima iteração, passe o diretório anterior em `--baseline`.

Para corrigir a apresentação de evidências já capturadas, sem repetir ou alterar os resultados do jogo:

```bash
python tools/iterate.py --review-only artifacts/<iteracao-existente>
```

O comando regenera HTML/ZIP, preserva o HTML anterior como `review-legacy.html` e mantém `run.json`, logs e capturas originais. Essa operação não representa uma nova aprovação dos testes.

Os objetivos e a rubrica estão em `docs/ux-contracts.json`. O navegador usa cliques e teclas reais sobre o canvas; a ponte `?test=1` é somente leitura. Cada clique espera a confirmação de interação pelo próprio Control, evitando atrasos fixos frágeis no renderizador da nuvem. `&visual=1` congela apenas respiração/vagalumes ambientais para capturas repetíveis; animações de combate continuam ativas. Não há métodos para alterar o jogo a partir do teste.

Os gates incluem orçamento de energia, efeitos sem dupla conjuração, cancelamentos preservando a run, captura/evolução/substituição, foco, ordem das camadas, títulos das cartas, contraste de botões sólidos, persistência, opções aplicadas às cartas atuais e pools limitados. Cinco formatos são exercitados em menu, combate, pausa, opções e texto ampliado. A suíte Godot injeta eventos de controle para testar roteamento; não comprova controle físico. Erros e testes vazios falham, e fontes modificadas durante a execução invalidam a tentativa.

O relatório distingue gates automáticos de revisão estética. Observe renders em tamanho real e o vídeo: prioridade da arena, colisões de texto, escolhas claras, duração de feedback e consequências das recompensas. Compare com a versão anterior e registre o que melhorou e o que piorou. Uma diferença de pixels só mostra mudança. Beleza, diversão, acessibilidade completa e performance em hardware exigem avaliação própria; não recebem um número automático.

## Ferramentas

Godot fica fixado em 4.6.3; Playwright e Pillow em `tools/requirements-browser.txt`. Instale as dependências e o browser no mesmo ambiente:

```bash
source tools/environment.sh
python tools/install_godot.py
python -m pip install -r tools/requirements-browser.txt
python -m playwright install chromium
```

O Playwright instala seu encoder de vídeo junto do browser. Nesta nuvem, Chromium e FFmpeg já são ferramentas do sistema; o encoder existente foi ligado ao cache de Playwright, sem download. `--video` exige um encoder acessível no cache indicado por `PLAYWRIGHT_BROWSERS_PATH`. O vídeo é evidência visual, sem captura do áudio; sons têm QA de PCM/clipping e precisam também de audição em hardware.

Para diagnóstico rápido após uma falha, `python tools/browser_smoke.py --output test-results/diagnostico --no-matrix` é explícito e marca a matriz como não executada. A aceitação completa usa `iterate.py`; ele não tem um atalho que apresente verificações omitidas como aprovadas. O CI executa o mesmo comando e publica as evidências como artifact, sem publicar o jogo.
