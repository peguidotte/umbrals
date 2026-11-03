# Desenvolvimento sobre a main atual

A base desta integração é a main `56e987b`, com batalha coletiva, expedição, save e
visual atualizados. O ramo antigo de refatoração fica preservado no histórico
(`4cebd55`); seus modelos do protótipo anterior não são o contrato do jogo atual.

## Preflight obrigatório

Antes de planejar uma alteração conectada ao repositório, execute
`python tools/harness.py preflight --fetch`. Main significa a branch atual do GitHub;
não ofereça a main local desatualizada como destino padrão. Compare commits e contratos
antes de reutilizar evidência antiga. Integre mudanças concorrentes preservando funções,
assets, saves e decisões do produto. Nunca resolva divergência sobrescrevendo a main.

## Responsabilidades atuais

- `main.gd`: composição, comandos, roteamento e foco. Inspeção, recompensas/captura, diálogos, registros e feedback têm donos em `ui/`; sessão/persistência em `session/` e protocolo Web em `ui/browser_bridge.gd`. Continua grande: novas extrações devem reduzir coordenação coesa, sem criar um helper com referência ao main.
- `rules.gd`: estado e execução da batalha; `battle/` mantém alvos, iniciativa,
  preparação inimiga, condições e reações puros, além de ciclo de cartas, planejamento, avaliação, resolução e recompensas com entradas explícitas.
- `domain/selection_planner.gd`: automação limitada pelo custo e orçamento real de ações.
  O adaptador em Rules mantém callers antigos; planejamento não escreve seleção/RNG.
  Custo zero não cria um limite fictício de três cartas.
- `expedition/expedition.gd`: navegação e único Rules ativo; snapshot/restore validados.
- `session/run_save.gd`: duas gerações e integridade de checkpoint; perfil separado.
- `expedition/replay.gd`: comandos permitidos, sem I/O, setters arbitrários ou bridge.
- `content/`: Resources por espécie, poder, item e encontro, com manifestos ordenados; formas e arestas explícitas. `content.gd` é a fachada de consulta e mantém naturezas, passivas e configuração curada. Projeções de compatibilidade são derivadas, nunca editadas. Leia `docs/content-authoring.md`.
- `ui/`: telas e componentes; grimório já separa catálogo, galeria e ficha. Novos
  componentes devem emitir intenção e receber dados/serviços explícitos, sem guardar main.
- `assets/`: versões imutáveis por domínio/ID, com produção fixada em runtime-lock.json.
  Não copie artes para um segundo catálogo nem resolva dependências por latest.
- `tools/harness_lib/registry.py`: tarefas, dependências e cobertura; wrappers não
  mantêm listas concorrentes. Resultados/user data pertencem à tarefa, não à raiz global.

Os modelos em `domain/models/` são snapshots tipados e validados usados em planejamento, eventos e restore. O estado vivo continua nos dicionários de Rules; esta rodada não converte todo o runtime em objetos tipados. Catálogos de teste são instâncias isoladas e consultas devolvem cópias.

## Guard incremental e dívida existente

`tools/architecture-baseline.json` registra métricas da main de origem, sem alterá-la.
`architecture_checks.py` verifica dependências, ciclos, domínio puro, RNG local,
fronteira de testes, comandos em views e concentração. Módulos novos continuam limitados
a 350 linhas significativas (400 para um novo coordenador). As exceções históricas
são explícitas: main, rules e mapa já excediam esses limites antes desta integração.
Seus tetos não podem crescer, e novas ocorrências de acoplamento são rejeitadas.

Não regenere a baseline para aprovar uma regressão. Reduza-a conforme extrair donos
coerentes. Uma baseline verde não significa que os problemas históricos estão resolvidos.
Os casos negativos provam que alterações acima desses tetos e acoplamentos novos falham;
o guard lexical não substitui testes de comportamento ou revisão.

## Contratos para novas mudanças

- Crie uma espécie com `python tools/umbrals.py author <id> --fallback ember`;
  revise seus dados/arte e rode as suítes `catalog` e `catalog-authoring`.
  Novo comportamento de traço exige implementação e registro em `battle/traits.gd`.
- Poderes, itens e encontros usam `tools/content_authoring.py`; valide também o item na mochila, contagem, plano e codex, além de sua execução. Novo comportamento de item registra handler e schema de parâmetros, sem adicionar branches ao catálogo.
- Evoluções são arestas com IDs estáveis; aceitam ramificações e mais de duas formas.
  Não adicione `stage`, índices de formas ou switches por espécie nas mecânicas/views.
- Modificações determinísticas exigem decisão explícita de compatibilidade e atualização
  de RULESET quando necessário. Conteúdo mecânico participa do digest; prosa e arte
  ficam fora dele. Migrações são explícitas e testadas com fixture antiga congelada.
  Adições compatíveis usam uma transição auditada; parâmetros e IDs de efeitos fazem parte da identidade. Nunca trate uma identidade desconhecida como save vazio. Veja `docs/save-format.md`.
- Views recebem dados e emitem intenção; não guardam main/host/coordinator nem escrevem
  regras. Feedback usa eventos públicos e cancelamento após awaits. I/O e protocolo
  de plataforma têm donos próprios, fora do domínio.
- O guard rejeita novos acoplamentos e crescimento acima da dívida medida. Não aumente
  a baseline para aprovar mudanças. Ainda há dívida explícita no coordenador, fachada
  de Rules e mapa; isso não bloqueia adicionar conteúdo com os contratos atuais nem
  autoriza afirmar que toda a arquitetura está concluída.

## Validação proporcional

Use primeiro suíte/caso/cenário afetado, com `plan --changed` como orientação. Preserve
exemplos numéricos e testes de mutação da main. Antes de fechar, congele fontes e execute
o grafo completo; revise capturas/vídeo. Documentação e políticas não comprovam imagem,
diversão, áudio ou hardware. Nunca apresente teste focado/cached como aceitação completa.
