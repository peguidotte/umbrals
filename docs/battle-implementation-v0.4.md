# Primeira implementação da batalha v0.4

Este registro preserva a primeira fatia coletiva. O estado implementado mais recente
está no [fechamento V04-BAT-04A/B](battle-closeout-v0.4.md); a estrutura da batalha
não aguarda nova entrevista. A [próxima entrega recomendada](first-expedition-plan-v0.5.md)
é a expedição com escolhas de rota, mantendo playtests de 0.4 em paralelo.

Estado: **primeira fatia jogável implementada e validada localmente**. Esta fatia implementa o núcleo escolhido na entrevista;
não encerra o marco 0.4 nem demonstra equilíbrio ou diversão. A versão de produto
permanece 0.3.0 durante a integração. Direção: [contrato de batalha](battle-design-v0.4.md)
e [referência visual aprovada](references/battle/00-aprovada/README.md).

## Resultado observável e escopo

**V04-BAT-01:** jogar com HP individual, posições superior/central/inferior e
iniciativa por velocidade, começando com um Umbral e mantendo até três ativos
por escolha. A interface deve permitir identificar dono, alvo, custo e resultado.
Ações, compra cíclica e trocas sustentam essa primeira experiência; mapa,
mercadores, progressão persistente do Refúgio e o catálogo completo são fatias
posteriores.

## Contrato entre os trabalhos paralelos

- **Conteúdo:** `scripts/content.gd` oferece atributos por espécie/estágio,
  poderes com custo, alvo, alcance, prioridade e ordem estável, além dos elencos
  e padrões inimigos dos encontros.
- **Regras:** `scripts/rules.gd` mantém indivíduos e vagas, instâncias de cartas,
  fila dos dois lados, plano inimigo comprometido, custos, nocaute e recompensas.
  A regra não acessa nós de interface, arquivos ou serviços.
- **Interface:** `scripts/main.gd` coordena as telas; atores, cartas e mão ficam
  em `scripts/ui/`. Ações do jogador passam pela mesma validação com mouse,
  teclado e controle. Mudanças de regra notificam o HUD por sinal.
- **Apresentação:** efeitos não alteram a simulação. O helper `battle_art.gd`
  usa regiões de atlas em tempo de renderização, preservando os PNGs originais;
  recursos vetoriais originais continuam como fallback.
- **Validação:** expectativas numéricas e invariantes em Godot, mutações
  representativas e controles reais no navegador. A ponte optativa de teste é
  somente leitura e respeita o nível de informação inimiga.

Um indivíduo tem UID, espécie, estágio, passiva, HP máximo/atual, Ataque, Defesa,
Velocidade, proteção, condições e vaga. Vaga −1 indica reserva; 0/1/2 representam
superior/central/inferior. Identidade e cópias não são transferidas a outro dono
ao trocar. Uma vaga é um alvo estável, mesmo se o ocupante mudar.

Cada técnica declara seu lado-alvo e alcance: `single`, `upper_pair`,
`lower_pair` ou `all`. A iniciativa usa prioridade explícita e velocidade do
dono, sem depender dos cliques. Os números e exceções do catálogo inicial são
valores para protótipo, não balanceamento aprovado.

## Critérios de aceitação desta fatia

1. Iniciar com um ativo e seis cartas; manter o limite de seis integrantes e de
   três ativos, sem exigir trio nem dar uma ação exclusiva por criatura.
2. Selecionar alvos e reconhecer HP, condições e informação inimiga por ator.
   Golpes em duas posições preservam o alcance quando há vagas vazias.
3. Resolver aliados e adversários por velocidade; poderes impedidos por nocaute
   não executam. Água/raio respondem à ordem efetiva de iniciativa.
4. Cartas de reservas aptos ficam suspensas. As de incapacitados continuam no
   ciclo, bloqueadas. Compra e descarte não duplicam ou recuperam instâncias.
5. Troca/entrada planejada custa ação e só executa ao Conjurar. Quem entra recebe
   ataques na vaga e contribui a partir da próxima compra normal.
6. Resortear passa a rodada inteira. Reposição após nocaute acontece entre
   rodadas; reviver só permite agir na seguinte.
7. Oculto, parcial e completo preservam o mesmo plano/resultado/RNG. Prévia e
   inspeção não revelam a fila secreta nem garantem efeitos interrompíveis.
8. Completar o percurso de batalhas/recompensas por controles reais, com foco,
   modais, texto ampliado e movimento reduzido funcionais. Revisar renders nos
   formatos definidos em `ux-contracts.json` e a sequência de feedback.

## Evidência e limites

A rodada final `artifacts/battle-v04-final-20261018T231232307414Z` foi aprovada sem falhas:

| Evidência local | Resultado |
|---|---|
| Regras e invariantes | 9557 verificações; 100 percursos com heurística determinística |
| Preferências, foco, input e inicialização | 49 verificações; teclado/controle sintéticos na cena |
| Mutações representativas | 2 detectadas: trait removido e quarta ação indevida |
| Navegador por controles reais | 754 verificações; duas rotas até a vitória, captura/evolução/entrada de reserva e 3×3 real |
| Formatos | 1280×720, 1440×900, 1920×1080, 1024×768 e 2560×1080; opções e texto ampliado |
| Arte/proveniência | 46 assets verificados; PNGs e metadados originais preservados |
| Exports locais | Web, Linux e Windows gerados; Linux inicia/encerra sem erros em headless |

A rodada preserva 39 capturas, snapshots, vídeo, logs, hashes e `review.html`
portátil. A [revisão visual](visual-review-v0.4.md) registra composição, sequência
de impactos e limites. Hash das fontes verificadas:
`8fd66359d3d5304ac17c4260ee719bbe5d131327b806691df609705e708e158b`. Documentação de resultado e texto do
empacotador foram atualizados depois da captura; nenhuma regra, UI ou arte do
jogo mudou após essa rodada.

As tentativas anteriores permanecem em `artifacts/`: duas falharam por comparar
campos internos ao contrato público de teste; outra atingiu o limite externo de
15 minutos no último formato. Uma repetição foi interrompida deliberadamente
para corrigir a mão durante o feedback. O limite passou a 30 minutos, mantendo
todas as verificações. A rodada final durou cerca de 16 minutos. Falhas não
foram convertidas em aprovações; notas de cada tentativa explicam a correção.

**Limites:** ainda faltam cinco primeiras sessões humanas, avaliação de
especialização/cooperação/proteção, equilíbrio e poses/animações completas.
O percurso começa com Brasa, oferece Orvalho e depois Faísca; Musgo está no
catálogo/fixtures, sem oferta natural nesses três encontros. Não há mapa,
mercador, aprendizado de técnicas em loja ou save de run. Modificadores de mão
e ações têm suporte/testes de dados, sem um catálogo de aquisição por relíquias.
Os itens jogáveis são poção/reanimação; artefatos e o catálogo completo são futuros.

WebGL por software, startup Linux headless e input sintético não comprovam
execução em Windows, controle físico, áudio em hardware ou desempenho mínimo.
Cem vitórias da heurística não comprovam equilíbrio ou diversão. O marco 0.4 e
a versão de produto permanecem abertos/em 0.3.0, respectivamente.

## Fatia elemental posterior

V04-BAT-03A acrescenta natureza independente do golpe, resistências por espécie,
Semeado/Brotação/Floração/Incêndio, Interferência, escolha inicial e capturas
complementares. A [especificação e validação](natures-status-reactions-v0.4.md)
registra o resultado atual, preservando os contratos coletivos e a versão 0.3.0.

A revisão posterior [V04-BAT-04A](battle-closeout-v0.4.md) substitui a captura
sempre na reserva por destino explícito e corrige a reinserção de cartas.
