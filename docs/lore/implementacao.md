# Lore nas implementações futuras

Este guia complementa [AGENTS.md](../../AGENTS.md), a
[skill Umbral](../../.agents/skills/umbral/SKILL.md), o [roadmap](../roadmap.md)
e os [contratos de arquitetura](../architecture.md). Base desta conciliação textual: `f29752c`.
Não é uma ordem de mudar gameplay nem uma revogação das decisões existentes.

## Conciliação com decisões e conteúdo existentes

| Registro atual | Relação com a lore | Como tratar |
|---|---|---|
| Roadmap, “Backstory proposta” | Noite da Fenda, Guia de Ecos, santuários, origem em memória/natureza e evolução como memória recuperada são uma proposta anterior. A lore confirma Umbrais anteriores aos humanos e nascimento majoritariamente natural. | Preservar o histórico; não apresentar essa sinopse como cosmologia confirmada nem supor que ela foi toda aprovada. Origem e evolução narrativas precisam de conciliação. |
| D01, equipe por run | Perfil/códice/desbloqueios separados da expedição; retomar preserva indivíduos, passivas e evolução. A lore prevê sobrevivência do protagonista, equipe nova por run e reencontros especiais; a equipe anterior não volta inteira como coleção permanente. | Manter D01 e o save atual. Explicação do reset e reencontros ainda precisam de design; “em aberto” na lore não revoga o contrato nem autoriza permanência universal. |
| D46, fantasia da abertura | Pessoa comum usa carta mágica para capturar; vínculo concede cartas de poderes. A lore descreve protagonista especial e poderes próprios dos Umbrais. | Registrar a tensão “pessoa comum”/“especial” para revisão, sem decidir a origem. Conceder cartas de poderes não implica criar os poderes da criatura ou dar mana ao humano. A natureza da carta permanece aberta; não reescrever a abertura aqui. |
| D02 e escolha inicial | A preferência antiga por três (PDF do jogo, pp. 5 e 7) foi superada pelas quatro opções do direcionamento posterior. `Content.STARTERS` contém Brasa, Musgo, Faísca e Orvalho; `Rules.new_run` cria um indivíduo. | Escolher um entre quatro; não iniciar com quatro companheiros nem reabrir a divergência histórica. Ver [contrato da seleção](../natures-status-reactions-v0.4.md) e [fontes](fontes.md). |
| D10/D37, incapacitação e reanimação | Nocaute não é morte definitiva; resgate/sepultamento narrativo permanece futuro. | Não equiparar KO à morte de um lendário ou ao desaparecimento de um conceito. |
| [Histórias do grimório](../codex-stories-v04-05g.md) | Já há prosa autoral implementada, com memórias e referências à Fenda. A própria entrega mantém a revisão narrativa aberta. | Ler os Resources atuais antes de escrever novas histórias; catalogar conflitos em tarefa própria. Prosa existente não confirma toda a backstory nem deve ser apagada automaticamente. |
| [Arte v0.4](../art-direction-v0.4.md), D31 e D47 | Batalha tem alvo visual aprovado; produto se chama Umbral, sem subtítulo. | Preservar nome, layout, referências e assets versionados. Design exploratório da lore não substitui aprovações existentes. |

## Onde implementar quando houver uma tarefa autorizada

| Área | Dono atual | Cuidados de lore e contrato |
|---|---|---|
| Histórias de formas | [Resources de espécies](../../content/species/) | Campo `lore` de cada forma; poderes pertencem aos Umbrais. Não editar projeções derivadas como uma segunda fonte. |
| Prosa de poderes, itens e encontros | [Poderes](../../content/powers/), [itens](../../content/items/), [encontros](../../content/encounters/) | Descrição não concede habilidades; separar texto de valores. A [fachada](../../scripts/content.gd) consulta o catálogo. |
| Regras, captura, evolução e autonomia | [Rules](../../scripts/rules.gd) e [battle](../../scripts/battle/) | Afinidade muda pelas ações; força pode influenciar obediência inicial sem garantir permanência. Isso não cria automaticamente medidores, testes de força ou sorteios de recusa/partida. Preservar UID/passiva, arestas explícitas de formas e cópias existentes; evolução não adiciona cartas automaticamente. |
| Cartas e execução | Contrato de combate e D03 | O recurso atual é ações compartilhadas, sem energia separada. Aliases antigos `energy` não são mana humana nem autorização para reintroduzir um recurso. Origem/funcionamento narrativo das cartas continua aberto. |
| Continuidade | [Expedição](../../scripts/expedition/expedition.gd), [sessão](../../scripts/session/) e [save](../save-format.md) | Já existe save/continuar exato. Reencontro entre runs não está definido por isso; não reutilizar UID isolado como identidade mundial sem projetar essa fronteira. |
| Aplicação e apresentação | [Mapa de arquitetura](../architecture-map.md) | Main compõe, application coordena, UI recebe dados e emite intenções. O grimório existente não fecha o papel narrativo do mentor. |

## Fluxo para agentes

1. Execute o preflight e leia o roadmap, [mundo](mundo.md),
   [primeiro jogo](primeiro-jogo.md) e as [pendências](pendencias.md) relacionadas.
2. Identifique o status de cada afirmação e o comportamento já implementado.
   Registre conflitos e suas fontes; não decida silenciosamente qual fonte vence.
3. Faça apenas as mudanças autorizadas. Se depender de decisão aberta, apresente
   opções concretas a Pedro e avance no trabalho independente. Não reabra decisões
   já ratificadas como se fossem desconhecidas.
4. Siga [autoria de conteúdo](../content-authoring.md) e os donos atuais. Prosa/arte
   ficam fora da identidade de gameplay; mudanças determinísticas exigem decisão
   de compatibilidade. Não invalidar saves por uma revisão de história.
5. Valide conforme o escopo: documentação requer links, integridade e revisão dos
   status; catálogo/gameplay exige suítes pertinentes; UI/experiência exige as
   skills e o harness prescritos no AGENTS.md. Headless não é aprovação visual.
6. No PR, cite decisões/fontes, tensões e verificações. Atualize o registro de
   iteração sem declarar marcos de produto concluídos por uma entrega documental.
