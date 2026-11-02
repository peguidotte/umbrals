# V04-UX-05H — opções na direção dourada

A tela anterior mantinha sliders cinza, switches/painéis roxos e uma coluna
longa sem agrupamento, destoando do menu e do grimório escolhidos. A captura
nativa anterior está em `test-results/settings-gold/01-before.png`.

`ui/settings_menu.gd` agora apresenta as mesmas opções sobre a floresta aprovada,
com a fonte editorial Cormorant, papel/verde profundo/ouro e moldura botânica
existentes. Áudio e Acessibilidade ficam à esquerda; Informação inimiga fica à
direita, com descrição junto de cada modo e indicação textual “Em uso”. Sliders
e switches são controles nativos com indicadores vetoriais em ouro; switches
também diferenciam posição/forma quando ligados. Não foram criados novos assets
de imagem ou alterados os arquivos de arte aprovados.

O conteúdo usa containers e rolagem; o rodapé com Voltar fica fora da rolagem.
A largura se adapta à janela, a altura é limitada para evitar um painel vazio
em telas mais altas, e as colunas passam a uma única coluna em espaços
estreitos. O painel recalcula seu tamanho quando as quebras de linha informam
o mínimo final, evitando que a primeira medição empurre o rodapé para fora da
janela. Texto ampliado continua ligado à preferência existente.

A integração em `main.gd` só delega a montagem da tela. Os IDs semânticos e a
ordem de navegação foram preservados. Escolher um modo atualiza a seleção sem
reconstruir o modal, mantendo foco e rolagem. As preferências, salvamento e
aplicação de áudio/acessibilidade usam o mesmo serviço anterior. A mudança da
informação durante a batalha continua valendo para o próximo plano, com a mesma
IA. A mesma tela atende título e pausa, retornando à origem com Esc/B/Voltar.

## Verificação focada e revisão visual

Armazenamento isolado; sem suíte completa de combate, conforme o escopo de
validação solicitado pelo usuário para estas alterações de UI.

- `tests/settings_menu_test.gd`: 27 verificações headless e 31 com render nativo.
  Exercita entrada real de teclado/eventos de B, volume, sequência de foco,
  switches, reconstrução após texto ampliado, escolha exclusiva de informação,
  persistência, saída/reabertura e opções dentro da pausa. Confirma que cartas,
  time, checkpoint e RNG não são alterados ao consultar/configurar a tela.
- `tests/title_menu_test.gd`: 28 verificações headless do fluxo existente.
- Capturas nativas em 1672×941, 1280×720 e 1024×768. Confirmadas as dimensões
  reais das janelas/capturas; texto e rodapé dentro do painel, sem cortes de
  controles ou legendas. No texto ampliado, as descrições dos modos e os três
  switches permanecem legíveis, com Voltar fora da área rolável.
- Evidências em `test-results/settings-gold/`: `headless-3.log`, `native-4.log`,
  `title-regression.log`, `02-options.png`, `03-large-text.png`,
  `05-1280x720.png` e `05-1024x768.png`. A falha de geometria da primeira
  tentativa está preservada em `native-1.log`; foi corrigida na implementação.

Os switches e marcadores vetoriais são construídos em código, sem arquivos
raster adicionais. Não houve alteração do catálogo, balanceamento, perfil do
grimório ou formato do save. Render nativo não é teste no navegador; controle
físico, celular e desempenho em hardware não foram verificados nesta fatia.

Produto permanece 0.3.0, marco 0.4 aberto. Próxima fatia de consistência sugerida:
Como jogar e Créditos, que ainda usam o modal anterior. A revisão de narrativa
e artes de consumíveis do grimório permanece separada.

## Revisão V04-UX-05I — margem e nome confirmado

O feedback do usuário identificou pouco respiro entre Voltar e o ornamento
inferior. A margem inferior do conteúdo passou de 28 para 52 pontos; o controle
e seu brilho/moldura ficam dentro da área segura do painel, também com texto
ampliado. Removida a linha de marca acima de Opções.

O nome confirmado do jogo é **Umbral**, sem subtítulo. Atualizados nome da
janela/projeto, créditos, metadados de exportação, texto do pacote/servidor e
documentação vigente. Na abertura, um pequeno recorte do cenário sem texto,
com bordas suaves, cobre apenas a linha antiga gravada no atlas. Logo, folhas,
comandos e arquivos de arte originais permanecem preservados. O diretório
legado de dados não mudou; não houve migração/reset de preferências ou save.

Validação desta revisão: 30 verificações headless e 34 nativas de opções,
incluindo o afastamento do botão da moldura e o nome configurado. Capturas
nativas do título, opções, texto ampliado e formatos menores revisadas em
`test-results/settings-gold/`. Comparação anterior e logs finais em
`test-results/settings-refinement/` (`settings-headless-final.log` e
`settings-native.log`). Sem exportação/publicação ou suíte completa de combate.

O usuário adiou explicitamente o redesenho de **Como jogar**, pois as mecânicas
ainda vão mudar e até a necessidade dessa tela será reavaliada. A sugestão da
fatia anterior fica suspensa; nenhum conteúdo ou acesso ao guia foi removido.
