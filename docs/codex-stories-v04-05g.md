# V04-UX-05G — histórias e descrições no grimório

O painel de evolução ocupava espaço da ficha sem ajudar a conhecer o Umbral.
A pedido do usuário, a ficha passa a abrir em **História**, com uma segunda
aba **Poderes e traços** para os dados de jogo. Itens, poderes e passivas usam
**Descrição** e **Efeito**. O texto flui em containers nativos e a ficha rola
quando o conteúdo não cabe, inclusive com texto ampliado.

Uma forma já descoberta continua acessível pelo atalho compacto “Ver Ignivar”
ou “Ver Brasa”, junto ao nome/natureza. O painel ilustrado de evolução foi
removido. Nomes, histórias e atalhos de formas desconhecidas permanecem ocultos.
O retorno contextual de 05F agora restaura também a aba interna de origem.

`content.gd` contém prosa para as onze formas/Umbrals de encontro presentes,
os dois consumíveis e os dezoito poderes atuais. As histórias desenvolvem
memórias e hábitos do [estudo de identidade](creature-identity.md), usando os
nomes do catálogo em execução. Esses textos são uma primeira redação autoral;
não aprovam os outros redesenhos/espécies daquele estudo nem encerram a revisão
narrativa. Valores, regras, descoberta, save e RNG não foram alterados.

Também corrigidos nesta ficha:

- A categoria ativa tem indicação própria; Itens já não mantém Umbrals aceso.
- Molduras usam o template vazio, evitando fragmentos do retrato de Brasa em
  cartas de itens/poderes. Cenário e ilustração respeitam o tamanho da carta.
- Texto ampliado usa legendas nativas, sem cobrir as imagens com placas escuras.
- Alternar uma aba restaura foco imediatamente; uma restauração atrasada não
  captura a ativação rápida do próximo link.

## Verificação focada

Armazenamento isolado, sem executar a suíte completa de combate, conforme o
escopo de validação solicitado pelo usuário:

- `tests/codex_story_test.gd`: 21 verificações com render nativo do Godot em
  1672×941. História, descrição de poder/item, efeitos reais, descoberta oculta,
  formas, retorno à aba/foco de origem e texto ampliado.
- `tests/codex_navigation_test.gd`: 28 verificações headless. O teste usa a
  rolagem real do controle focado, pois o novo corpo da ficha tem outra altura.
- `tests/gold_ui_test.gd`: 38 verificações headless do fluxo existente.
- Capturas nativas `01-brasa-history`, `04-item-description` e `06-large-text`
  inspecionadas em `test-results/codex-story/`. História ocupa toda a largura
  disponível, abas e atalho não colidem e o texto ampliado mantém as artes.

Logs finais: `native-final5.log`, `navigation-final2.log` e `flow-final2.log`,
no mesmo diretório ignorado de evidências. Tentativas anteriores, incluindo
falhas de sincronização/foco, foram preservadas. Render nativo não comprova
comportamento no navegador ou em controle físico. A ilustração de consumíveis
ainda reutiliza o ícone de mochila existente; esta fatia não adiciona item art.

Versão 0.3.0 e marco 0.4 permanecem. Próxima fatia sugerida: distinguir as artes
dos consumíveis e revisar os textos em playtest, mantendo o desbloqueio por
descoberta e a direção dourada escolhida.
