# Lobby — V05-UX-01

Ao clicar Jogar, o jogador encontra o lobby com a expedição e seu ponto salvo.
Os retratos representam somente os indivíduos dessa expedição; HP e posição
em campo/reserva vêm do mesmo snapshot público já validado. Nova expedição
ainda pede confirmação antes de substituir a run. Treino mantém seu fluxo
separado. Não há mudança de regras, RNG, catálogo ou formato de save.

Melhorias e visitas por vínculo têm espaços informativos sem ações fictícias:
melhorias indisponíveis nesta versão, visitas como possibilidade futura.
Não existem moeda, compra, bônus, afinidade persistida ou coleção permanente
implementados nesta fatia. A identidade dourada/botânica atual foi preservada,
sem acrescentar arquitetura medieval nem novos assets.

A view continua recebendo uma cópia pública e emitindo os quatro callbacks
existentes. Layout usa containers, duas colunas quando há largura e uma quando
não há; conteúdo rola com o foco, enquanto Voltar fica no rodapé fixo. A escala
de texto e movimento reduzido seguem os serviços e botões atuais.

## Evidências

Resultados focados iniciais: title e expedition-ui passaram em
`artifacts/harness/lobby-focused-20261104T131035313173Z-55bf2d/`.
A revisão renderizada inicial passou em
`artifacts/harness/lobby-render-20261104T131124288134Z-500788/`:
interface nativa e cenário real de browser title, com capturas desktop e
844×390. No desktop, comandos e áreas futuras ficam separados e legíveis;
no formato baixo, o conteúdo rola e Voltar permanece visível.
Esses resultados focados não equivalem à aceitação completa.

O fechamento completo passou em `artifacts/lobby-v05-ux01-verified/`:
14.419 verificações de regras, 1.142 de domínio/UI, 2311 de navegador,
dez cenários, cinco formatos, oito mutações e fontes inalteradas. O relatório
`run.json` registra `status: passed` e cobertura completa. Capturas e notas
ficam em `review-notes.md`; HTML/ZIP são gerados pelo harness.

A tentativa `artifacts/lobby-v05-ux01-final/` foi preservada como falha: a nova
asserção de teclado presumiu foco em Continuar, mas o serviço existente
restaurava Nova expedição. Somente o teste foi corrigido; nenhum código do
jogo mudou entre tentativas. A repetição completa acima passou em cerca de
25 minutos. Exports Linux/Windows passaram separadamente no alvo
`artifacts/harness/lobby-final-focus-fix-20261104T133820233423Z-dfa855/`.
Windows foi exportado, não executado em Windows.

As capturas de lobby sem save, com save, texto ampliado, 720p, 4:3,
ultrawide e 844×390 foram inspecionadas diretamente. No formato baixo,
parte do conteúdo exige rolagem; o rodapé permanece acessível. A fixture de
seis integrantes foi validada nativamente, sem alegação de captura visual
desse estado. A abertura do HTML por `file://` foi bloqueada pela política
do Chromium (`ERR_BLOCKED_BY_ADMINISTRATOR`), sem nova tentativa ou contorno;
a revisão visual se baseou nos PNGs reais, não na página HTML.
Aprovação estética do jogador, controle físico e desempenho em hardware seguem
pendentes; visitas e melhorias precisam de definição de produto antes de implementação.
