# Informação inimiga — alternativas para o Umbral

Estado: **parcial confiável escolhido pelo usuário como padrão; implementação
pendente**. Oculto, parcial e completo serão apresentações do mesmo plano da IA.
Disponibilidade e progressão de ajuda continuam em entrevista. Desenvolve a
[proposta de batalha](battle-design-v0.4.md); o [contrato configurável](intent-visibility-design.md)
detalha arquitetura, campos revelados e critérios futuros.

## A diferença para as referências

No 1×1, o alvo de um ataque adversário costuma ser evidente mesmo quando o golpe
é desconhecido. No 3×3 proposto para o Umbral, esconder golpe e alvo cria duas incertezas, além
da mão sorteada. O jogador também distribui ações de um orçamento coletivo.
Como as cartas de incapacitados continuam no ciclo por decisão do usuário,
perder um indivíduo reduz opções e pode piorar compras futuras.

[Into the Breach](https://www.subsetgames.com/itb.html) apresenta os ataques
inimigos antecipadamente; a [apresentação de design dos criadores](https://media.gdcvault.com/gdc2019/presentations/Into%20the%20Breach%20Postmortem%20Final.pdf)
inclui essa telegrafia entre seus pilares. Isso é uma referência para dificuldade
por restrições e ameaças concorrentes, mesmo quando a informação é visível.

A [documentação de IA do próprio PokéRogue, na branch beta consultada](https://github.com/pagefaultgames/pokerogue/blob/beta/docs/enemy-ai.md)
descreve avaliação de golpes e alvos. Portanto, informação oculta não equivale
a escolha puramente aleatória: aprender repertórios e tendências pode permitir
antecipação. Essas referências não demonstram qual política funcionará no Umbral;
as consequências abaixo são hipóteses de design.

## Três modelos-base

| Modelo | O que aparece antes de agir | Que decisões favorece | Concessões e exigências |
|---|---|---|---|
| **Informação completa** | Ação escolhida, alvo/área, efeitos e dano calculável com os estados conhecidos. | Proteção precisa, interromper a ameaça certa, maximizar uma combinação e decidir qual dano aceitar. | Pode aumentar tempo de cálculo e incentivar otimização exata. Exige ordem, redirecionamentos e mudanças de estado muito claros. Não torna a batalha automaticamente fácil. |
| **Informação parcial confiável — padrão escolhido** | Categoria confirmada como direção. Proposta: ataque/defesa/preparo/suporte e individual/área; intensidade qualitativa somente com significado estável. Golpe exato, alvo individual e dano ficam ocultos. | Preparação por risco, conhecer o comportamento da espécie, proteger vulneráveis, provocar/interceptar e investir em leitura. | Precisa de sinais consistentes e respostas reais. Preparações especiais de chefes são conteúdo explícito a definir; um sinal mostrado nunca pode mentir. |
| **Sem intenção antecipada** | Estados, repertório já observado e pistas gerais da espécie; ação e alvo aparecem na execução. | Aprender padrões, formar equipes robustas e escolher entre investimento ofensivo e margem de sobrevivência. | Favorece cobertura geral, cura e controle preventivo; pode reduzir o valor de defesas muito específicas. Precisa limitar perdas inevitáveis e testar frustração no 3×3. |

Uma quarta ideia, **conhecimento adquirido**, pode complementar qualquer modelo:
o códice registra técnicas e tendências observadas, sem necessariamente revelar
a próxima ação escolhida. Conhecer possibilidades é diferente de conhecer a
decisão atual. O catálogo permanente de D01 oferece lugar para isso.

## Cenários comparáveis

### 1. Salvar um especialista

Faísca está com 7 HP. Musgo pode gastar uma ação para dar 10 de proteção a um
aliado ou provocar ataques individuais elegíveis. Um adversário tem um golpe
de 12 de dano entre suas opções. Valores são exemplos, sem alegação de equilíbrio.

- **Completa:** se o golpe mirar Faísca, protegê-la evita o nocaute e permite usar
  as ações restantes no plano ofensivo. O problema é escolher a melhor alocação.
- **Parcial:** a indicação de ataque individual forte dá motivo para proteger
  Faísca ou redirecionar a ameaça, mas há custo de oportunidade se o alvo real
  fosse outro. O problema é escolher uma resposta robusta com informação limitada.
- **Oculta:** o adversário pode atacar ou preparar algo. Proteger pode ser
  prudente ou desperdiçar uma oportunidade; atacar pode ganhar o encontro ou
  deixar o especialista cair. Sem tendências aprendíveis, isso vira aposta.

Provocação precisa de duração, elegibilidade e custo explícitos. Não presumir
que um comando barato possa absorver gratuitamente quatro ataques. A política
de informação altera o valor dessa técnica e exige outro balanceamento.

### 2. Uma combinação que pede preparação

O jogador quer investir duas ações em preparar uma técnica para a próxima rodada.
Com informação completa da rodada atual, pode aproveitar uma janela defensiva
adversária; a rodada seguinte ainda pode exigir adaptação. Com informação parcial,
os sinais de preparação e a história do inimigo ajudam a escolher o momento.
Sem informação, precisa de margem de HP, controle ou disposição para arriscar.

Se preparar for frequentemente punido sem resposta, dano imediato e controle
preventivo tendem a ganhar valor. Se a janela for sempre segura e barata, a mesma
sequência pode dominar. Os três modelos precisam de testes de variedade.

### 3. Um chefe prepara um ataque em área

Um ataque muito forte atinge os três ativos na próxima rodada. No modelo
completo, o jogador compara proteção, cura e interrupção sabendo os valores.
No parcial recomendado, esse evento excepcional recebe um sinal forte e uma
janela explícita de resposta, mesmo que golpes comuns mantenham alvo oculto.

Esconder também essa ameaça pode encerrar uma run sem o jogador reconhecer
uma oportunidade de reagir. Se essa for a fantasia escolhida, o encontro precisa
oferecer margem e respostas apropriadas; apenas inflar HP não resolve a leitura.

### 4. Mão com cartas de incapacitados

O jogador mantém integrantes vivos, mas a mão não oferece uma combinação útil.
Passar renova a mão e deixa o adversário executar o turno. Informação completa
permite calcular o preço; a parcial permite avaliar o grau de risco; sem intenção,
o jogador depende do repertório aprendido e da sobrevivência provável.

Com a renovação de mão já confirmada em D14, cartas bloqueadas consomem vagas
naquela rodada e voltam ao descarte normal ao encerrá-la. Elas podem reaparecer
em ciclos posteriores enquanto o dono permanecer incapacitado. Não removê-las
automaticamente e não conceder compra gratuita quando ele cai.

## A dificuldade e a meta mudam de lugar

| Aspecto | Completa | Parcial | Oculta |
|---|---|---|---|
| Defesa de um alvo específico | Precisa e mensurável | Cobertura de risco ou redirecionamento | Depende de previsão de comportamento e margem |
| Cura/defesa geral | Compete com soluções mais eficientes | Compra segurança contra cenários possíveis | Tende a ganhar importância como seguro |
| Dano explosivo | Remove ameaças identificadas | Remove riscos prováveis | Pode ser usado para impedir qualquer resposta |
| Leitura/sondagem | Só agrega se mostrar informação adicional | Pode revelar decisões e reduzir incerteza | Pode virar requisito se ameaças não derem resposta |
| Principal risco de experiência | Cálculo excessivo | Sinais vagos ou inconsistentes | Perda percebida como inevitável |

São tendências a observar, não resultados medidos. Não prometer que um modelo
produzirá mais profundidade ou diversão antes dos playtests.

Como ilustração, quatro ataques que escolhem independentemente e por igual um
entre quatro alvos têm `1 − (3/4)^4 ≈ 68,36%` de chance de ao menos um atingir
um membro específico. Isso não descreve a IA proposta: apenas mostra por que
o risco acumulado no 4×4 difere da intuição de uma ameaça isolada. Regras de
alvo e comportamento da IA ainda serão desenhadas.

## Contratos que eu preservaria em qualquer modelo

1. A IA define o plano da rodada antes da seleção do jogador, conforme a política
   escolhida. Não troca de golpe secretamente depois de ver a combinação montada.
2. Informações reveladas são verdadeiras. Mudanças por provocar, interromper,
   incapacitar ou outro efeito seguem regras explícitas; não são uma nova escolha
   escondida para contornar a defesa.
3. A prévia calcula com exatidão as ações próprias conhecidas. A resposta inimiga
   mostra somente o que a política autoriza: certeza, intervalo ou desconhecido.
   Não expor o plano oculto indiretamente por um HP futuro exato.
4. UI/inspeção não sorteia nem muda o plano; RNG e plano sobrevivem ao save.
5. Uma sondagem pode mudar o que o jogador conhece, sem mudar o ataque escolhido.
   Evitar que a sobrevivência dependa de comprar uma carta de informação específica.
6. Informação é uma configuração própria, separada dos atributos e comportamento
   da IA. Um desafio pode fixá-la se declarar isso antes da run; não ocultar dados
   silenciosamente ao subir números ou trocar de bioma.

## Como comparar sem confundir as causas

Usar o mesmo time, baralho, estado, mão e plano inimigo para comparar primeiro
os três níveis de informação. Observar escolha, tempo de decisão, explicação
da derrota, uso de proteção e disposição para tentar outra composição.

Depois ajustar ameaças, cura e recursos separadamente: o encontro balanceado
para intenção completa não é automaticamente justo com intenção oculta. Simulação
confere regras e probabilidades; sessões humanas avaliam compreensão e diversão.

**Direção confirmada:** parcial confiável por padrão e suporte aos três níveis
sobre o mesmo plano. Comparar apresentações continua útil para calibrar sinais e
respostas. Disponibilidade, desbloqueio e vigência da troca continuam em entrevista.
