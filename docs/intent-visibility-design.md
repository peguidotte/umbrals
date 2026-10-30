# Intenção configurável — um plano, três apresentações

Estado: **núcleo de projeção implementado e validado localmente na primeira fatia coletiva**. Ver [escopo e evidências](battle-implementation-v0.4.md). D21 confirma parcial confiável como
padrão e suporte a oculto/parcial/completo sobre o mesmo plano inimigo. O
[estudo de cenários](enemy-information-study.md) desenvolve as concessões.

## Separação recomendada

O núcleo calcula e guarda um `EnemyTurnPlan` antes da seleção de cartas: rodada,
ator, técnica e vagas-alvo originais (D39/D40), além dos sorteios que o contrato definir como
antecipados. `intent_visibility` nunca participa da escolha de técnica/alvo, da
semente ou da resolução. A IA não escolhe outra jogada ao mudar a configuração.

Uma projeção pura, `present_intent(plan, visibility, public_state)`, produz os
campos autorizados. Arena, inspeção, prévia e dicas recebem essa observação; o
resolvedor usa o plano real. Esconder rótulos depois de entregar o plano inteiro
aos widgets facilita vazamentos pela prévia. Esta separação garante coerência
da apresentação, sem pretender impedir inspeção da memória de um jogo local.

| Campo antecipado | Oculto | Parcial padrão proposto | Completo |
|---|---|---|---|
| Categoria da próxima ação | Não | Sim | Sim |
| Individual ou área | Não | Não no protótipo atual | Sim |
| Técnica e efeitos específicos | Não | Não | Sim |
| Alvo individual escolhido | Não | Não | Sim |
| Dano inimigo calculável | Não | Não | Exato quando determinístico com estados conhecidos |
| HP e estados atuais públicos | Sim | Sim | Sim |
| Repertório aprendido no códice | Sim | Sim | Sim |

Categoria é a direção confirmada; os demais campos do parcial são proposta.
Não usar adjetivos de intensidade sem faixas compreensíveis e estáveis. Variação
aleatória ainda não decidida aparece como intervalo/probabilidade no completo,
sem inventar valor exato. Uma preparação visível de chefe pode ser uma pista do
mundo em todos os modos: definir isso no conteúdo, sem exceção secreta da UI.

Provocação, interrupção e nocaute modificam a execução conforme regras explícitas,
sem sortear outra intenção para contornar a resposta do jogador. D40 mantém o
ataque destinado à vaga: quem substituir o alvo original recebe o golpe.
Com D38, aliados e adversários podem se intercalar por velocidade; efeitos
próprios são condicionais quando uma interrupção anterior puder impedi-los.
A prévia não garante que todo poder selecionado chegará a executar.
Só mostrar intervalos calculados com possibilidades públicas, nunca mínimos ou
máximos derivados do plano secreto. O histórico revela o ocorrido após a execução.

A fila de iniciativa também passa pela projeção de informação. Não exibir
prioridade, identidade da técnica, máscara de posições ou posição exata de uma
ação inimiga quando isso revelar campos ocultos. Uma ordenação das próprias
cartas pode ser mostrada como planejamento, com interrupções desconhecidas
assinaladas, sem reconstruir a fila secreta para a UI. Se atributos atuais forem
públicos, inspecionar Velocidade não deve revelar qual prioridade foi escolhida.

## Configuração durante a partida

**Default de MVP confirmado na aceitação das recomendações:** parcial por padrão,
três modos desde o início e mudança aplicada ao próximo plano/turno. D35 foi
inicialmente adotada por delegação e agora está ratificada. O pedido de ter os
níveis e configurar durante a partida já existia em D21; não reabrir essa pergunta
ampla. O menu pode ser aberto durante a batalha.
A troca não custa ações nem refaz a IA, e sua vigência aparece claramente. Um
controle de desenvolvimento permite alternância imediata para comparar o mesmo
estado. Revelar e esconder não faz esquecer: a preferência comum vale no próximo
turno. Retomar precisa preservar o plano e sua política vigente; não pode refazer
a decisão inimiga.

O default do MVP não reduz ajuda automaticamente após um número de vitórias. Podemos sugerir
outro nível após aprendizado; uma vitória não mede preferência por informação
oculta. Desbloquear oculto por progresso e assistência decrescente são alternativas
levantadas pelo usuário, ainda sem adoção. Se houver desafios/classificações no
futuro, declarar nível e trocas. Não criar um sistema competitivo nesta fatia.

## Custo e validação

A projeção dos três níveis tende a ter custo pequeno se prevista desde o início.
O trabalho relevante é integrar prévia/inspeção, preferência, save e verificação.
Mesma IA não significa mesma dificuldade prática: informação muda o valor de
provocar, curar e aceitar dano. Não estimar horas sem dividir essas integrações.

Critérios para implementação posterior:

- Mesmo estado/semente e mesma jogada preservam plano, resultado e RNG nos três
  níveis. Inspeção e troca não consomem sorteios.
- Parcial corresponde à categoria/escopo reais; completo explica mudanças de
  ocupante da vaga e redirecionamentos causados por efeitos conhecidos. A área
  exata superior/central/inferior só aparece se autorizada pela projeção.
- Prévia, destaques e inspeção não revelam campos proibidos. Logs de execução
  não antecipam o próximo turno.
- Retomar mantém plano, preferência e eventual mudança pendente.
- Playtests com um, dois e três aliados ativos, reservas e até três adversários avaliam
  compreensão, respostas defensivas e percepção de justiça em cada nível.

## Pirates Outlaws

Adicionado às inspirações a pedido do usuário, especialmente por sua lembrança
de leitura parcial das ações. A [página oficial da Fabled Game](https://fabledgame.com/pirates-outlaws)
confirma expedições com construção de baralho e combinações e disponibiliza
capturas de batalha. O texto consultado não especifica todos os campos de intenção;
a política exata do original não foi verificada nesta fatia. O contrato do Umbral
é uma adaptação própria, não uma reprodução alegada desse jogo.
