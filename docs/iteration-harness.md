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

Os gates incluem orçamento de ações, efeitos sem dupla conjuração, cancelamentos preservando a run, captura/evolução/substituição, foco, ordem das camadas, títulos das cartas, contraste de botões sólidos, persistência, opções aplicadas às cartas atuais e pools limitados. A mão conjurada permanece visível até terminar a resolução. Cinco formatos são exercitados em menu, combate, pausa, opções e texto ampliado. A suíte Godot injeta eventos de controle para testar roteamento; não comprova controle físico. Erros e testes vazios falham, e fontes modificadas durante a execução invalidam a tentativa.

Cada etapa usa um limite padrão de 30 minutos: quatro percursos, cinco formatos de tela e gravação em WebGL por software podem ultrapassar 15 minutos nesta nuvem. Esse limite não reduz a cobertura nem altera as condições de aprovação. A fatia
elemental acrescenta os percursos de Musgo e Faísca; o job completo do CI tem
45 minutos para incluir instalação, quatro percursos, matriz e exports nativos.

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

As revisões V04-BAT-04A/B acrescentam destino de captura com cancelamento, captura
direta no campo, faixa de comandos e histórico da última rodada. As mutações
incluem reinserção em bloco e destino ignorado, além das três
regressões elementais/orçamento. O roteiro elemental prepara uma única semente
antes do Fogo e respeita a Provocação visível, sem enfraquecer a exigência das
quatro reações no navegador.

As outras duas mutações cobrem reposição parcial no início do encontro e
repetição de uma reposição recusada. Alvos de cura no roteiro carregam o lado
aliado e são reproduzidos por cliques reais em aliados, sem alterar a ponte
somente leitura ou relaxar a igualdade da mão.

V04-BAT-04B acrescenta a oitava mutação: bloquear indevidamente uma troca
voluntária depois de recusar a reposição. A captura de vídeo de 04A segue
registrada; 04B altera elegibilidade/copy, sem mudar código de movimento.

V05-RUN-01/SAVE-02 acrescenta `tools/expedition_checks.py` ao gate e um segundo
percurso de navegador em `tools/expedition_browser_smoke.py`. A suíte antiga
continua exercitando o treino de batalha; a nova usa o fluxo principal com mapa,
as duas rotas, descanso, save/reload, toque/teclado e formatos de mapa.
`run.json` separa `browser` e `expedition_browser`; a página de revisão incorpora
as duas galerias, sem misturar capturas simuladas com renders reais.

## Limite de execução no ambiente de nuvem

`--step-timeout <segundos>` permite ampliar o limite por etapa (padrão: 1800),
sem alterar percursos, asserts ou critérios de aprovação. O valor usado fica em
`run.json`. Use um limite maior quando o render por software/gravação exceder o
limite disponível; preserve tentativas interrompidas. Reinício do ambiente não
representa uma aprovação nem uma falha funcional do jogo. V04-UX-05A retomou
a execução sem nova gravação contínua: não houve mudança de movimento, e o vídeo parcial
da tentativa interrompida permanece disponível para revisão.

A captura complementar final de V04-UX-05A tem vídeo próprio da mesma batalha,
registrado após o gate; não é uma gravação contínua dos quatro percursos.

## V04-UX-05C — validação focada autorizada

O usuário aprovou as seis melhorias do menu e dispensou explicitamente a suíte
completa por sua duração. Nesta fatia, usar `python tools/title_checks.py`,
`python tools/assets.py validate --base-ref origin/main`, exportação Web e
`python tools/title_polish_review.py --video` com o ambiente de
`source tools/environment.sh`. O primeiro launcher isola XDG; o segundo usa
perfis descartáveis e entrada real no navegador. Não executar novamente
`tools/iterate.py`, simulações de batalha, mutações ou as rotas completas.

Cobertura: assets/pins; poses/efeito e movimento reduzido; teclado/toque e foco;
áudio limitado/mute; novos formatos; Jogar → Nova → mapa → título → cancelar
Nova → Continuar. Preservar relatórios de falha, capturas e vídeo. O hash do
pacote identifica o executável efetivamente aberto; documentar separadamente
uma correção posterior e sua nova verificação. Não apresentar este escopo como
uma regressão completa do jogo ou teste em aparelho físico.

`python tools/title_typography_review.py` reproduz o complemento focado de fonte, toque em três formatos, cancelar Nova e retomada exata; não executa batalhas.

## Integração na main — 01/11/2026

Checagens focadas antes da integração de 05A–05D: 675 de UI/estado/catálogo/boot,
28 do menu/áudio/checkpoint e 113 de expedição/save/cena; assets 58 releases e
126 arquivos válidos. Sem repetir regras completas, mutações ou rotas longas
no browser, conforme a dispensa explícita do usuário.

A integração atualizou o clique sintético da carta para usar o transform da
composição atual. O teste do menu agora aguarda a liberação real dos playbacks
via WeakRef (prazo de 2 s) antes de encerrar, em vez de assumir que 100 ms bastam
para mixer e main loop drenarem recursos. Há uma asserção de liberação; avisos
de leak continuam falhando. Três execuções consecutivas passaram. Nenhum código
de runtime precisou mudar nessa revisão da integração.
