# V04-UI-06A — componentes do grimório e tema de controles

Objetivo técnico solicitado pelo usuário: facilitar as próximas iterações de UI
do marco 0.4, preservando o visual e a experiência já aprovados. A dificuldade
era o grimório de 490 linhas reunir catálogo, galeria, ficha e histórico, e o
tema dos controles ficar embutido na tela de opções.

## Onde alterar cada parte

| Mudança | Responsável |
| --- | --- |
| Espécies, poderes, efeitos, histórias e descrições | `scripts/content.gd` |
| Categorias, projeção dos registros e ordem por descoberta | `scripts/ui/codex/catalog.gd` |
| Retratos, cartas, legendas e moldura de seleção da galeria | `scripts/ui/codex/gallery.gd` |
| História, descrição, traços, poderes e links da ficha | `scripts/ui/codex/record.gd` |
| Categoria/página/seleção, histórico de Voltar e restauração de foco | `scripts/ui/codex.gd` |
| Grupos e controles das Opções | `scripts/ui/settings_menu.gd` |
| Aparência de botões nativos, switches, sliders e barras de rolagem dourados | `scripts/ui/gold_controls_theme.gd` |

O catálogo é uma projeção de leitura: não cria nodes, não registra descobertas
e não grava o perfil. Centraliza categorias, tamanho da página e busca por ID.
A galeria recebe só os registros da página; a ficha recebe o registro e a aba
atual. Ambas emitem pedidos por sinais. Nenhuma delas modifica página, histórico
ou sessão por conta própria.

O controlador do grimório passa de 490 para 247 linhas. Ele continua dono do
histórico e do cancelamento de restaurações pendentes, preservando a navegação
rápida, dois níveis de links, página/rolagem/foco e descoberta oculta. A seleção
visual pertence à galeria; a altura dinâmica do texto pertence à ficha.

O tema de controles retorna uma nova Theme por construção, sem depender da
instância das Opções ou das preferências. As Opções passam a montar cabeçalho,
conteúdo e rodapé em funções distintas. A aplicação e o salvamento das
preferências continuam no serviço existente, coordenado por `main.gd`.

Os componentes usam `setup` antes de `render`, recebem o registrador semântico
do proprietário e mantêm os mesmos IDs de interação. O controlador conecta os
sinais uma vez ao construir a tela. Layouts e regiões de atlas permanecem nos
respectivos componentes de apresentação.

## Evidência e limites

- `python tools/title_checks.py`: 371 verificações headless sem falhas nas
  sete suítes existentes de assets, menu, grimório, navegação, histórias,
  opções e startup. Nenhum teste foi alterado para acomodar a extração.
- `tests/codex_navigation_test.gd`: 28 verificações com render nativo,
  incluindo teclado e eventos de B, links encadeados, foco, rolagem e saída.
- Oito capturas antes/depois em 1672×941: título, opções, texto ampliado,
  história de Brasa, poderes, Musgo, registro desconhecido e item. Todas têm
  pixels idênticos sob a mesma fixture. As capturas de opções ampliadas e
  história foram também inspecionadas. A comparação comprova preservação
  dessas composições; não é uma nota de qualidade visual.
- Relatórios/capturas em `test-results/ui-components/`; relatório headless
  em `test-results/title-scoped/report.json`. Comparação em
  `visual-comparison.json`, log nativo em `navigation-native.log`.

Não houve alteração de regras, conteúdo, assets, formato de save ou nome do
jogo. `main.gd` continua responsável pela sessão; não foi reorganizado nesta
fatia. A suíte completa de combate, exportação e navegador não foram executados,
seguindo o escopo de validação focada autorizado pelo usuário. Produto 0.3.0 e
marco 0.4 permanecem. Como jogar continua adiado.

Próxima fatia técnica sugerida: extrair a apresentação de inspeção/plano do
coordenador principal quando esses fluxos forem a próxima prioridade, usando o
mesmo contrato de sinais e IDs. Não criar uma nova hierarquia genérica de telas
apenas para eliminar pequenas diferenças entre as composições existentes.
