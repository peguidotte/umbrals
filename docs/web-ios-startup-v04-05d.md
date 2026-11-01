# V04-UX-05D — abertura no Safari/iPhone

Plano antes da edição, 01/11/2026. O usuário enviou a tela do Safari informando
que a página falhou repetidamente. A publicação anterior e testes Chromium
com toque emulado não comprovaram funcionamento no iPhone físico.

Escopo: abertura e orçamento de memória/renderização Web; preservar composição,
regras, chaves/origem e esquema de save. Sem suíte completa, mantendo a orientação
explícita de validação focada.

Diagnóstico inicial: logs do Worker sem erros. O export usa densidade nativa e
pode multiplicar o framebuffer por nove em DPR 3; o loader compila o motor e
baixa/remonta o pack simultaneamente, conservando buffers temporários. A causa
exata do encerramento no aparelho não está comprovada por um screenshot.

Plano: medir canvas em DPR 3; limitar render Web à resolução CSS; baixar partes
diretamente no buffer final, evitando cópias por parte; separar compilação do
motor do carregamento do pack; manter verificação de integridade e tratamento de
falhas; checar boot real com DPR alto, rotação, toque e entrada no fluxo de save.
Atualizar a mesma prévia privada e documentar limites, sem afirmar Safari físico
como testado. A contrapartida da resolução CSS é perder supersampling Retina,
aceitável para reduzir custo de um jogo com direção pixel art.

## Implementação e evidências

`project.godot` adiciona somente `window/dpi/allow_hidpi.web=false`. A comparação
dos hashes de runtime com 05C confirma que nenhum script, cena, regra ou pin
foi alterado nesta correção. A perda de supersampling fica restrita ao Web.

No repositório separado do Site, `web-boot.js` escreve chunks de rede diretamente
no buffer final e valida tamanho/hash. `web-entry.js` aguarda `engine.init()`
antes de iniciar o preload, mantendo o início normal do engine e o save.

- Antes: canvas 1179×2556 em viewport CSS 393×852/DPR 3; depois: 393×852, mesmo
  layout lógico 1600×3468. Redução de 88,9% dos pixels do framebuffer.
- `node tests/web-boot.test.cjs`: 10 verificações, zero falhas. Inclui pack exato,
  uma alocação final, ausência de buffers completos por parte, tamanho inválido,
  truncamento/corrupção rejeitados e validação do motor.
- `tools/web_retina_review.py`: 13 verificações em 40,65 s, zero erros. DPR 3 em
  retrato/paisagem, DPR 2 desktop, toque, rotação e retomada do mesmo snapshot
  público após reload. O trace comprova que a primeira parte é solicitada após
  concluir a compilação WASM. Capturas foram abertas e inspecionadas.
- Exportação Web e sintaxe JS passaram. Sem suíte completa de combate, conforme
  a instrução do usuário; o comportamento de combate não foi alterado.

Evidências: `test-results/V04-UX-05D-before/`, `V04-UX-05D-after/` e
`V04-UX-05D-retina/`. Hash do pacote:
`88bd0311b42f83d4dc599af7049f58f875fa8e38acba703d868830b6ec1f6de9`.
Fontes de runtime: `d2ad41e8812e9045cdb3a5f323814b3f180863f6eed66cc07d3e46b457ab4da9`.

Essas medições verificam as mitigações e a abertura em Chromium. Não comprovam
que a causa do encerramento no aparelho era memória nem que o Safari físico
foi corrigido. Modelo/iOS e nova tentativa do usuário permanecem necessários
para confirmar esse ambiente. Os logs do serviço consultados não continham
erros; isso tampouco substitui um trace do processo WebKit no aparelho.

Um complemento com animação e shader ativos passou mais sete verificações em
DPR 3: abertura, orçamento CSS, relógio de animação ativo, reação ao toque,
permanência no menu, estado/storage inalterados e ausência de erros.
`test-results/V04-UX-05D-live/report.json`. O viewport continua sendo emulado
em Chromium, e não deve ser descrito como um teste de Safari.

## Publicação

O serviço confirmou `succeeded` em 01/11/2026 17:25:43 UTC.
Mesma prévia privada e origem do save:
https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site/?build=ios-88bd0311b42f

Fonte do Site: `821cf3b85a0d8c95e603f298ad8b803a0a44f6f7`.
Deployment: `appgdep_6ae776037e2481919e4bf4b904646c1f`.
Versão: `appgprj_6ae29e832674819195964322c38d7d93~appgver_e99842cfdd308191bc655fb291dee813`.
Archive SHA-256: `1657c28b382143c62ee68361a07a429fb3d2162566c4adf718a2e11426a24df3`.

A publicação é comprovada pelo serviço e a execução foi verificada localmente no
adaptador exato. Safari/iPhone físico continua pendente da nova tentativa do
usuário; não foi marcado como aprovado. Só o repositório separado do Site teve
commit/push. O repositório do jogo mantém as mudanças revisáveis no workspace.
