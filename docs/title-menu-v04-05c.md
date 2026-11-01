# V04-UX-05C — acabamento do menu

Plano registrado antes da implementação em 01/11/2026. O usuário aprovou as
seis melhorias em conjunto e pediu validação focada, dispensando a suíte completa.

1. Submenu Jogar com a linguagem violeta/marfim, retratos do time salvo e ponto
   real da expedição. Nova e treino continuam secundários.
2. Hover, pressão e foco seguindo o chanfro dos botões, com retorno discreto.
3. Cartas em camadas independentes, flutuação e rotação suaves, reação ao toque.
4. Mesmo bosque preenchendo formatos largos e estreitos; áreas de toque maiores
   sem inflar a arte, texto grande e composição adaptável.
5. Transições curtas entre telas de menu, preservação do foco e alternativa
   estática com movimento reduzido.
6. Água/bosque discreto e sinais de cristal/reação mágica nos buses existentes.

Preservar a arte escolhida, regras, esquema e origem do save, iniciativa,
informação inimiga e limites de integrantes. Produto continua 0.3.0.

Implementação: apresentação em `scripts/ui/`; `main.gd` coordena telas e fornece
um resumo público do checkpoint validado. Novas imagens têm módulos e pins
explícitos; a referência 1.0.0 permanece intacta. Sem delegação nesta fatia.

Aceite verificável: navegação por teclado/toque; foco e pressione distinguíveis;
três cartas com transformações independentes; reação sem alterar jogo/save;
resumo do progresso verdadeiro; cancelar Nova preserva checkpoint; continuar
restaura o mapa; movimento reduzido estático; volumes zero silenciam os novos
sons; capturas reais e vídeo. Validação apenas de apresentação, navegação, assets,
exportação e fluxo do save afetados. Não executar novamente batalha completa,
simulações ou mutações. Resultados serão registrados após execução e revisão.

## Implementação entregue

- `title_menu.gd`: bosque independente cobrindo o viewport; logo limpa; polígonos
  com os pixels originais das três cartas, pivôs, fases e rotações diferentes;
  fitas/faíscas limitadas e pulso ao tocar. O efeito não muda estado ou RNG.
- `title_button.gd` e `title_theme.gd`: um padrão violeta/marfim para a abertura
  e seus submenus, foco com chanfro, hover e pressão suaves. Caption nativa em
  camada superior à moldura; área de toque independente da dimensão da arte.
- `journey_menu.gd`: retratos do catálogo, resumo real do checkpoint validado,
  até seis integrantes; Continuar/Nova/Treino com os callbacks anteriores. O
  aviso rotineiro de sucesso não duplica o resumo. Falhas/recuperação são visíveis.
- Vertical reorganiza cartas e comandos; formatos largos mostram o mesmo bosque,
  sem trocar de cenário nas margens. Jogar tem escala própria, rolagem quando
  necessária e fonte mínima equivalente a 14 px no dispositivo (16 px com texto
  ampliado). Toque de abertura tem pelo menos 44 px nos formatos emulados.
- Entrada de menu de 160 ms, sem atrasar o modelo, com exclusividade de input,
  restauração de foco e cancelamento de tweens anteriores. Movimento reduzido
  fixa poses, remove pulso/partículas e dispensa fade, inclusive na tela atual.
- Água/insetos, cristal de navegação/confirmação e acorde da carta são síntese
  original. Três vozes adicionais fixas, buses Music/UI existentes, volume/mute
  persistentes e desligamento gracioso. Não usa o RNG da batalha.

A logo e o fundo novos têm módulos 1.0.0 e pins explícitos. A referência anterior
`ui/title-menu@1.0.0` continua byte a byte intacta. A identidade de zero pixels de
05B é histórica: 05C introduz deliberadamente camadas, novo fundo limpo, foco,
movimento e adaptação de composição.

## Resultados efetivamente verificados

1. `python tools/title_checks.py`: **245 verificações**, zero falhas — 215 de
   consumo do catálogo, 27 de apresentação/áudio/ligação com save, três de startup.
   XDG isolado. Inclui seis retratos, poses independentes, movimento reduzido,
   vozes limitadas, sinais não vazios/sem clipping, mute e retomada exata do mapa.
2. `python tools/assets.py validate --base-ref origin/main`: **58 releases,
   126 arquivos**, zero falhas, releases da base preservados. Exportação Web passou.
3. `tools/title_polish_review.py --video`: **135 verificações** em 302,21 s,
   zero erros de página/engine/console. Teclado, hover, pressionado, toque emulado,
   cartas sem mudar jogo/storage, Nova/cancelar/Continuar, larguras e preferências.
   Capturas em 1672×941, 2560×1080, 1024×768, 844×390, 390×844 e 360×640.
   Dois PNGs de movimento reduzido idênticos. Pacote desta passagem:
   `ae85cc2c0ab3a47972bd6975a7bcb2ede90b77d32fbede84837daeb83ba4b18e`.
4. Após inspeção, aumentou-se somente a fonte de Jogar no celular, ocultou-se o
   aviso rotineiro duplicado e tratou-se a ausência de janela no headless. Só
   `journey_menu.gd` mudou desde o passo 3. A checagem nativa acima foi repetida;
   a conferência focada final acrescentou **18 verificações em 93,04 s**, sem
   erros, por toque em três formatos, resumo salvo e restauração exata. O pacote
   permaneceu fixo durante essa conferência:
   `da647026e1b6d0ea4504b5b3dd4fa0cf6cc6833500363c35ff60008e1f78ae59`.

Evidência principal: `test-results/V04-UX-05C-final/`; complemento final de
Jogar: `test-results/V04-UX-05C-typography-verified/`; nativo:
`test-results/title-scoped/`. Hash final das fontes de runtime (scripts,
shaders, cenas, project e pins):
`15e73929f5c2c44b315f72a5536df37c53967f71415ad41a9916282883831ba5`.
O complemento é uma validação do ajuste posterior; não se afirma que as 135
verificações rodaram novamente no último pacote.

5. A última revisão corrigiu a ordem de desenho das fitas/faíscas, colocando o
   fundo atrás da camada de efeitos. A checagem nativa voltou a passar (245);
   o teste libera suas amostras locais antes de sair, evitando avisos intermitentes
   exclusivos do encerramento do próprio teste. O adaptador real do Site abriu o
   pacote final, recebeu Jogar, carregou quatro imagens e reproduziu vídeo sem
   erros ou overflow. O vídeo foi novamente gravado nesse pacote. Hash final:
   `7307bbbccb4e27dcbe588fc759818b78fb47dea5f7cf28ff34bee3a88f29576e`.
   Relatório: `test-results/V04-UX-05C-hosted-adapter/report.json`.

O vídeo final real tem 44,92 s em `V04-UX-05C-hosted-adapter/video/`;
`card-effect-demo.webm` é o trecho 35–44,9 s sem carregamento, em 1280×720.
Mostra flutuação/reação e fitas na ordem de desenho corrigida, sem áudio gravado.
Os vídeos e capturas anteriores permanecem como histórico, com seus hashes.

## Revisão visual e limites

Foram abertas as capturas de abertura, foco, Jogar vazio/salvo, toque horizontal,
vertical pequena e ultrawide, além de frames da gravação. Cartas mantêm a arte
escolhida, o bosque preenche as margens e os comandos não se sobrepõem. O painel
mostra Brasa e 40/40 HP no checkpoint real de exemplo, com Clareira como próxima
parada. A revisão corrigiu os captions que ficavam sob a moldura e aumentou a
leitura do submenu no celular. A forma branca e o losango tornam o foco legível
além da cor. Na vertical há uma composição nova, adotada autonomamente.

Não foi feita a suíte completa, por instrução explícita do usuário. Não se
alega regressão completa de combate, execução em telefone/controle/GPU físicos,
leitor de tela, avaliação humana de diversão ou escuta subjetiva do áudio. A
validação do áudio cobre síntese, encaminhamento, mute e limite de vozes.

Tentativas preservadas: `V04-UX-05C-review-1` falhou no ambiente de gravação antes
de abrir o jogo; `review-2` foi exploratória (dois exports, não evidência de um
pacote fixo); `typography-final` foi rejeitada pela própria checagem de hash
quando houve reexport para o fallback headless. Logs nativos intermediários
preservam o erro de chanfro em largura inicial estreita e a correção do fallback.
O launcher agora grava saída de futuros timeouts. Esses registros não são
substituídos pelos resultados finais aprovados.

## Publicação confirmada

Em 01/11/2026, o serviço retornou `succeeded` para a mesma prévia privada:
https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site
Jogo atualizado: `/?build=menu-7307bbbccb4e`; capturas/vídeo: `/novidades.html`.

Deployment: `appgdep_6ae76da5f4d88191a56af4c3c649aa43`.
Versão: `appgprj_6ae29e832674819195964322c38d7d93~appgver_2e017e5a627481918ffee8c3886b376d`.
Fonte do Site: `982db3269a2f8c9dc4f94288655696496fcc5397`.
Arquivo publicado: SHA-256 `75e77521016250ec34d076bfb341360fc8e811efc1b22d03a25d2edc9bf75005`,
62 arquivos extraídos do commit enviado. Cada parte do pack tem até 16 MiB;
a reconstrução é sem perdas e verificada por SHA-256 no navegador.

Audiência privada/origem do save preservadas. Sem push no repositório do jogo.
Publicação comprovada pelo serviço; execução gráfica e entrada comprovadas
localmente no adaptador exato. Não se afirma teste remoto autenticado ou em
telefone físico. A página de novidades contém imagens reais e o vídeo final.

Toque final da carta: cinco verificações em 844×390 com o pacote publicado,
reação e áudio disparados, permanência no menu e jogo/storage inalterados.
`test-results/V04-UX-05C-touch-final/report.json`.

Fechamento preservado em `artifacts/V04-UX-05C-final-20261101T165257Z/closure-report.json`.
