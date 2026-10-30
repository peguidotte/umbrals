# Entrevista de batalha — estrutura fechada para o MVP

Estado em 29/10/2026: as decisões estruturais abaixo estão implementadas no
checkout, com fechamento técnico em **V04-BAT-04A/B**. Produto **0.3.0**;
playtests e acabamento do marco 0.4 continuam abertos. Este documento não é
mais uma fila de perguntas para começar a batalha.

Não reabrir formação, mão, reservas, iniciativa ou informação inimiga sem uma
necessidade nova demonstrada. Valores de protótipo e defaults desenvolvidos
por delegação não são aprovação literal de cada número pelo usuário.

## Já definido

| Tema | Direção confirmada |
|---|---|
| Campo e time | Um a três ativos por escolha; até seis no time. Início com um; 1 ativo e 5 reservas é legal. Nenhum efeito abre um quarto ativo. |
| Iniciativa | Velocidade individual define a ordem de atuação; aliados e adversários podem se intercalar (D38). Não adotar jogador sempre primeiro. |
| Posições e alcance | Linha de três posições por lado: superior, central e inferior, sem retaguarda. Individual, superior + central, central + inferior ou tudo (D39). |
| Alvo após troca | O substituto recebe o golpe destinado à vaga do integrante que saiu (D40). Não cancelar por simples troca. |
| Mão | Seis cartas por padrão, podendo aumentar ou diminuir através de itens e Umbrals (D36). Isso não altera ações ou capacidade do campo. |
| Repertório inicial | Três poderes por integrante, duas cópias de cada: seis cartas por dono (D36). Sem extras, 1/2/3 ativos aptos contribuem 6/12/18 cartas. |
| Aprendizado e evolução | Evolução preserva as cópias existentes, UID e passiva. Adicionar/substituir/aprimorar técnicas está definido como direção, mas loja/aprendizado ainda não estão jogáveis. |
| Reservas aptos | Cartas fora da mão, compra, descarte e embaralhamento ativos (D32). |
| Troca voluntária | Custa uma ação e só executa ao confirmar Conjurar (D33). Quem entra contribui na próxima compra normal, sem compra imediata. |
| Incapacitados | Cartas permanecem bloqueadas no ciclo (D19). Repor o integrante não apaga essa penalidade. |
| Reposição após nocaute | Gratuita entre rodadas, depois de toda a fila dos dois lados; não exige preencher o trio (D37/D38). |
| Reanimação | Reviver nesta rodada e agir na próxima (D37). Não compra ou recupera cartas gratuitamente. |
| Informação inimiga | Parcial confiável por padrão; oculto/parcial/completo sobre o mesmo plano da IA. Todos disponíveis desde o início; mudanças comuns valem na próxima rodada, sem redução automática da ajuda (D35 ratificada). |
| Captura | Escolha explícita Campo/Reserva; vaga livre sugerida e confirmação final. Captura entre encontros não custa ação (D44). |
| Naturezas e reações | Resistências explícitas por espécie, principal/secundária seletiva e controle sem perda geral de turnos (D41–D43). Quatro reações implementadas em V04-BAT-03A. |

## Defaults já implementados e verificados

- Três ações compartilhadas. Prioridades: trocas 100, itens 90, proteções 1,
  técnicas normais 0; depois velocidade e desempate estável por semente.
  Clicar primeiro não adianta água antes do raio. Ver [arquitetura](architecture.md).
- Quem sai do campo não executa seus poderes restantes. Quem entra recebe o
  golpe dirigido à vaga e acrescenta cartas na próxima compra normal.
- Instâncias são preservadas. Cartas de entrada se intercalam uniformemente
  com a compra; descarte só é reciclado quando ela acaba. Não há compra extra,
  bloco garantido do recém-chegado ou limpeza gratuita de cartas de KO.
- Reposição gratuita após a fila e no início de encontro com KO parcial.
  Recusar não repete o diálogo a cada rodada; mudar de ideia depois permite
  uma troca voluntária por uma ação. Perder o último ativo reabre recuperação.
- Reanimação custa uma ação pelo consumível atual e habilita poderes na rodada
  seguinte. Reanimar uma reserva não a coloca automaticamente no campo.
- O motor calcula capacidade de mão/ações com modificadores explícitos.
  Mão tem limite operacional 1–24, sem representar um teto de balanceamento
  confirmado. As ofertas e regras de cada futuro modificador não existem ainda.
- PLANO edita/inspeciona/conjura; comandos próprios mostram alvo/custo/velocidade;
  RESUMO apresenta efeitos já resolvidos, sem vazar intenção inimiga futura.

Os contratos e evidências atuais estão no [fechamento da batalha](battle-closeout-v0.4.md).
Os antigos oito de mão, jogador inteiro antes do inimigo, quatro ativos e
inserção de cartas por blocos não regem o MVP atual.

## O que ainda precisa de validação

Cinco primeiras sessões para compreensão, ritmo e balanceamento; clareza da
seleção de alvos, causalidade dos combos e custo das cartas bloqueadas.
Acabamento visual/mobile e execução em hardware/controle reais seguem próprios.
São trabalho de qualidade, não novas definições estruturais bloqueadoras.

## O que pertence às próximas fases

- **0.5:** rota da expedição, ofertas adquiríveis, relíquias/artefatos, edição do
  baralho, mercador, eventos e save/continuar.
- **0.6:** aprendizado mais amplo, catálogo, desbloqueios/códice e loja do
  Refúgio; persistência das compras entre runs ainda a definir conforme D01/D20.
- Resgate/sepultamento e ecos narrativos precisam de uma fatia própria; não
  mudar o nocaute reversível atual para morte permanente automática.

A [primeira expedição com mapa e save](expedition-implementation-v0.5.md) está
integrada e validada. O próximo incremento é V05-ECON-03, com mercador, edição e
relíquias adquiríveis; UX/playtests da batalha continuam em paralelo. A formação visual aprovada continua em
[00-aprovada](references/battle/00-aprovada/README.md); não gerar novas imagens
sem um objetivo específico.
