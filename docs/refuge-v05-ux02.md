# V05-UX-02 — sala de repouso explorável

Correção do pedido de lobby: o usuário descreveu uma sala em que um boneco anda,
consulta o grimório e prepara a partida. V05-UX-01 entregou somente um menu.
A entrada Jogar agora leva ao Refúgio. A direção visual desta primeira fatia foi
executada por delegação: interior contemporâneo, madeira, iluminação quente,
plantas e janela para o bosque. Não copia assets nem a planta de Hades.

## Comportamento

- WASD/setas, direcional ou analógico esquerdo movem o avatar. E/Enter/A interagem
  por proximidade; Escape/B volta ao título. Tab alcança os atalhos; clicar no
  chão devolve o foco à caminhada.
- A saída abre o painel existente de expedição: continuar, nova run e treino.
  Grimório abre a consulta real com descobertas persistidas. Atalhos de interface
  permitem os mesmos acessos com mouse/toque, sem exigir locomoção por toque.
- Móveis, vasos e limites da sala bloqueiam o personagem. A câmera é fixa; a
  transformação da apresentação preserva a geometria lógica em cada resolução.
- A bancada informa que melhorias estão indisponíveis. Não há compras, moeda,
  cura, NPC inventado nem visitantes por afinidade. A equipe salva continua
  exclusivamente no painel da expedição.
- Painéis suspendem movimento; fechar restaura posição e foco. O input precisa
  voltar ao neutro antes de retomar caminhada, evitando carregar uma tecla de
  um painel para o chão. Entrar novamente inicia no ponto seguro.
- Arte vetorial original e provisória, identificada na tela: avatar de jaqueta,
  calça e tênis com passada simples. Sem animações finais ou identidade narrativa
  atribuída ao protagonista. Movimento reduzido remove a passada cosmética,
  preservando deslocamento controlado.

## Fronteiras

RefugeRoom emite intenções; RefugeSpace contém apenas geometria da apresentação;
RefugeCanvas/RefugeArt desenham. ScreenHost controla a raiz e os painéis; main
conecta seus sinais. O painel Journey passa a se chamar Preparar expedição e
concentra as ações existentes. Foram removidos seus cartões de funcionalidades
futuras, agora representadas honestamente na sala.

Nenhuma mudança em regras, formato de save, catálogo, RNG, afinidade ou persistência.
A posição não entra no checkpoint. Continuar e treino usam os coordenadores
existentes. A ponte Web expõe somente posição, proximidade e estado visual para
observação; nenhum setter ou boot de teste foi adicionado à produção.

## Verificação e limites

A suíte nativa refuge registra input real do Godot: teclado e eventos sintéticos de
controle, colisões, velocidade diagonal, zona morta, proximidade, modais, movimento
reduzido e conservação de RNG/save/HP/estatísticas. Não representa controle físico.
As suítes anteriores mantêm os casos de continuar exatamente, confirmação/cancelamento,
treino e navegação. O cenário Web title inclui caminhada real até mesa, bancada e
porta, consulta do grimório e capturas; layout inclui a sala em cinco formatos.

Aceitação local completa aprovada em `refuge-v05-ux02-final-20261104T172236496738Z-73d9d1`
(2330,743 s), com fontes congeladas: suíte refuge (23 checks), regressões nativas,
compatibilidade, arquitetura, mutações, exports e dez cenários Web, incluindo as
rotas da expedição e cinco resoluções. Capturas reais de 1280×720, 1024×768 e
2560×1080 e quadros do vídeo real de title foram inspecionados: avatar, mobiliário,
estação de leitura, bancada e saída visíveis, com painéis acima da sala.

A primeira CI encontrou uma corrida na automação: o comando de caminhada era
liberado após uma leitura atrasada, ultrapassando o corredor e colidindo com a
mesa. Apenas o teste mudou para pulsos de teclado e leitura após a liberação;
colisões e asserts foram preservados. Repetição local `refuge-ci-input-sync-20261104T180210138054Z-c88daa`
aprovada com vídeo. O runtime é idêntico ao da aceitação completa; a nova CI do
PR #6 deve aprovar o HEAD corrigido antes de integração. Os relatórios e vídeos
ficam nos respectivos diretórios `artifacts/harness/` (não versionados).
Arte final, personagens narrativos, melhorias e visitantes são trabalho posterior.
A versão do produto continua 0.3.0; esta fatia não encerra os marcos humanos.
