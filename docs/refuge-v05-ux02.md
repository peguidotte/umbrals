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
- Painéis suspedem movimento; fechar restaura posição e foco. O input precisa
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

Evidência final de aceitação e revisão visual será registrada após o fechamento.
A primeira tentativa de percurso Web bateu na mesa por ultrapassar o corredor na
sincronização do teste; o trajeto foi corrigido sem relaxar colisões.
Arte final, personagens narrativos, melhorias e visitantes são trabalho posterior.
A versão do produto continua 0.3.0; esta fatia não encerra os marcos humanos.
