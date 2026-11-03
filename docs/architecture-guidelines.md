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

- `main.gd`: sessão, comandos e coordenação. Ainda contém layout/feedback a extrair.
- `rules.gd`: estado e execução da batalha; `battle/` mantém alvos, iniciativa,
  preparação inimiga, condições e reações puros.
- `domain/selection_planner.gd`: automação limitada pelo custo e orçamento real de ações.
  O adaptador em Rules mantém callers antigos; planejamento não escreve seleção/RNG.
  Custo zero não cria um limite fictício de três cartas.
- `expedition/expedition.gd`: navegação e único Rules ativo; snapshot/restore validados.
- `expedition/run_save.gd`: duas gerações e integridade de checkpoint; perfil separado.
- `expedition/replay.gd`: comandos permitidos, sem I/O, setters arbitrários ou bridge.
- `content.gd`: catálogo atual de quatro espécies/poderes/naturezas e textos. Ainda é
  centralizado e usa estágios ordinais; migrar isso exige preservar o combate atual.
- `ui/`: telas e componentes; grimório já separa catálogo, galeria e ficha. Novos
  componentes devem emitir intenção e receber dados/serviços explícitos, sem guardar main.
- `assets/`: versões imutáveis por domínio/ID, com produção fixada em runtime-lock.json.
  Não copie artes para um segundo catálogo nem resolva dependências por latest.
- `tools/harness_lib/registry.py`: tarefas, dependências e cobertura; wrappers não
  mantêm listas concorrentes. Resultados/user data pertencem à tarefa, não à raiz global.

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

## Próximas prioridades arquiteturais

1. Extrair inspeção, recompensas, navegação/foco e feedback restantes de main, preservando
   os IDs/tempos públicos. Evitar helpers com referência ao coordenador.
2. Portar os pacotes de conteúdo para o catálogo coletivo: espécies/formas e transições
   estáveis, poderes/traços por dono e assets referenciados por versão. Não importar os
   Resources antigos sem adaptar HP individual, naturezas, cópias conhecidas, reservas,
   seis integrantes e evolução sem cartas extras. Migrar saves com estágios ordinais.
3. Adicionar identidade do conjunto de regras/conteúdo e política de migração ao save e
   replay. Hoje a versão estrutural do checkpoint não identifica toda alteração de balanceamento.

Modelos tipados e catálogo por instância acompanham a segunda prioridade. O catálogo
atual é constante; fixtures devem modificar só suas instâncias, nunca seus dicionários.
Nenhuma dessas prioridades está concluída apenas porque o merge ou o harness passou.

## Validação proporcional

Use primeiro suíte/caso/cenário afetado, com `plan --changed` como orientação. Preserve
exemplos numéricos e testes de mutação da main. Antes de fechar, congele fontes e execute
o grafo completo; revise capturas/vídeo. Documentação e políticas não comprovam imagem,
diversão, áudio ou hardware. Nunca apresente teste focado/cached como aceitação completa.
