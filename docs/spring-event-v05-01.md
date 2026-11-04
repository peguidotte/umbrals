# V05-EVT-01 — uma decisão dentro da Nascente

Protótipo experimental revisável sobre main `e151ba2`. Produto continua 0.3.0.
Não é uma definição final de recompensas, economia, NPCs ou conteúdo da campanha.

## Direção e escolha de escopo

Pedro considerou viável ajustar a distribuição de técnicas, mas rejeitou oferecer
isso como uma recompensa genérica depois de todo combate. Pediu decisões
contextualizadas em salas, NPCs e situações, citando Hades e Balatro e possíveis
compras/vendas. Esta fatia usa a situação da Nascente já presente na bifurcação:
**descansar ou passar esse intervalo praticando com um Umbral**. Captura e evolução
continuam sendo as recompensas existentes dos combates.

A main já tinha um grafo fixo curto, combate/descanso, captura/evolução, cópias com
dono e checkpoints/replays. Não havia carteira, preços, compra/venda ou um sistema
genérico de NPCs/eventos. Não se acrescenta economia por inferência.

Alternativas para a próxima decisão de conteúdo:

| Opção | Benefício | Custo / decisão pendente |
|---|---|---|
| Nascente: descanso ou prática (protótipo atual) | Usa uma situação e uma escolha de rota reais, com custo de oportunidade legível. | Precisa de playtest e arte própria para parecer um lugar mais marcante. |
| Encontro com um praticante itinerante | Dá personalidade, diálogo e recorrência à mesma operação. | Identidade, vínculo e presença na jornada ainda precisam da direção de Pedro. |
| Mercador com compra e venda | Permite planejamento de recursos e oportunidades de salas distintas. | Exige definir moeda, fontes, preços, inventário e persistência antes de implementar. |

A Nascente é o menor teste funcional independente. A prosa sobre água e prática
não fixa origem de cartas, cosmologia, geografia ou um NPC canônico.

## Comportamento observável

Em expedições novas, confirmar a rota da Nascente entra numa sala persistida.
Entrar ainda não cura nem edita cartas. Esse caminho abre mão do combate da Mata
fechada e de sua recompensa; a decisão da sala abre a passagem ao guardião.

- Descansar mostra HP antes/depois e recupera 25% do máximo de cada aliado vivo,
  limitado ao máximo; não reanima e mantém todas as cópias.
- Praticar escolhe um aliado vivo (inclusive reserva), uma técnica doadora e uma
  receptora já conhecidas desse mesmo indivíduo. Só uma cópia muda; mínimo de uma
  cópia na origem e máximo de três no destino. Esses limites são hipóteses de teste.
- A confirmação mostra contagens antes/depois, total constante e HP sem cura.
  A prática custa abrir mão do descanso; não há taxa monetária ou cura escondida.
- Cancelar a escolha apenas descarta o rascunho. Pausa/opções/recarga também
  descartam rascunhos não confirmados; a sala e o intervalo ainda disponíveis
  permanecem no checkpoint. A entrada na rota já foi confirmada no mapa.
- A sala só se conclui uma vez. Não é possível praticar, curar em seguida ou entrar
  também na Mata fechada. A decisão não entra no perfil permanente.

O menor `instance_id` elegível em ordem lexical muda somente o campo `power`.
IDs são opacos: não são reconstruídos a partir da técnica nova. Dono, quantidade,
passiva, forma, técnicas conhecidas e os demais dados da instância permanecem.
Sem sorteio, compra gratuita, filtragem de KO ou alteração de orçamento de combate.

## Donos e compatibilidade

`battle/technique_practice.gd` oferece consultas puras e uma transformação
validada. `expedition/expedition.gd` possui a sala, sua confirmação e o estado vivo;
`application/expedition_flow.gd` coordena checkpoint e apresentação. `ui/spring_room.gd`
recebe um snapshot e emite intenções. Não guarda main, serviços de armazenamento
ou outra cópia mutável de regras.

O ruleset passa explicitamente de `expedition-rules-2` para `expedition-rules-3`.
O schema 2 recebe `event_revision`: 1 nas expedições novas, 0 nas migradas.
Saves/replays auditados da main anterior e da baseline histórica são aceitos
mediante os manifests congelados e a comparação conservadora já existente.
A migração de uma run antiga mantém a Nascente imediata e as mesmas ofertas,
instâncias, planos e RNG até o fim; salvar de novo conserva essa revisão 0.
Nenhuma identidade desconhecida ganha uma migração permissiva.

`tests/fixtures/expedition_rules2_replay.json` foi produzido **antes das mudanças**
na main `e151ba2`, com comandos reais de produção, primeiro prêmio e estado após
dois encontros, além do descanso antigo. É evidência de regressão congelada,
não um save pessoal. O novo comando de replay `event` aceita somente `rest`
ou uma prática com UID/técnicas explícitos; não permite setters ou RNG arbitrário.

## Evidências e limites

A baseline visual real percorreu as duas rotas anteriores em
`artifacts/harness/contextual-visual-baseline-20261104T214941804017Z-b76334/`.
O relatório é focado, não uma aceitação completa. A captura da Nascente antes da
entrada mostra a cura imediata anterior. Os testes novos cobrem operação,
limites, cancelamento, reservas, identidade, persistência e replay histórico.

A cena reutiliza a floresta e o ícone da Nascente existentes; não tem uma pintura
nova de sala nem NPC animado. A escolha contextual é o protótipo, não uma loja
pronta ou uma promessa de variedade procedural. Números, identidade do encontro
e benefício de diversão precisam de revisão e playtest humano.


A revisão focada passou em
`artifacts/harness/spring-browser-matrix-20261104T220301044530Z-a06706/`:
52 verificações nativas novas, fixtures validadas por checkpoint/replay e
escolha/cancelamento reais no navegador, com matriz de cinco resoluções e texto
ampliado. As capturas de chegada, prévia, 720p e 4:3 foram inspecionadas: o dono,
1→3, total constante e perda da cura são legíveis; confirmação/cancelamento ficam
fora da rolagem. A primeira captura revelou quebras de linha trazidas do nome de
carta; foram removidas apenas na apresentação da sala. Pausar agora ocupa um
comando compacto no canto. A composição ainda é uma interface de protótipo sobre
assets existentes, não uma sala ilustrada final.

Tentativas anteriores permanecem: `spring-first-check` (binding de ícone
corrigido), `spring-rules-check` (comparação de ints/floats do JSON normalizada
pelo restore real), `spring-focused` (relatório nativo passou a ser emitido no
stdout exigido pelo runner) e `spring-browser-review` (o guard de modal foi
corrigido para a raiz de mapa, exigindo cartas de batalha ocultas).
A aceitação integral posterior é registrada no PR/entrega; um foco verde não
substitui esse fechamento.
