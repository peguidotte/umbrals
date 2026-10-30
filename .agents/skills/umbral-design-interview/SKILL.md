---
name: umbral-design-interview
description: "Use para planejar ou aprofundar o roadmap e o design do Umbral em entrevistas por blocos, sempre com opções, recomendação fundamentada e registro de decisões."
---

# Entrevista de direção do Umbral

Adaptação local inspirada em Grill Me / grilling, de Matt Pocock. Leia a
[proveniência e as referências](references/sources.md). Este arquivo é
autossuficiente; não depende de uma ferramenta chamada Skill ou de outras skills
de entrevista instaladas. As preferências e autorizações do usuário prevalecem.

## Quando aplicar

Use ao discutir fases, identidade, batalha, criaturas, economia, construção de
baralho, evolução ou rejogabilidade do Umbral, quando decisões de produto ainda
precisam de direção. Não reabra uma entrevista para uma correção clara ou um
detalhe de implementação já coberto pelas decisões existentes.

O usuário quer recomendações e delegou o preenchimento das lacunas. Entrevistar
deve reduzir a carga de decisão e produzir um plano concreto.

## Preparação

1. Leia `AGENTS.md`, a skill `umbral`, `docs/roadmap.md` e os contratos pertinentes.
2. Consulte o código para descobrir o que existe. Fatos do repositório e pesquisa
   são responsabilidade da IA; não pergunte o que pode verificar.
3. Separe decisões confirmadas, recomendações adotadas por delegação, propostas e
   evidências verificadas no jogo. Implementação e validação são dimensões
   diferentes: um sistema implementado ainda pode exigir playtest.
4. Escolha a fase e mapeie dependências. Pergunte agora apenas por decisões que
   não dependam de outra resposta ainda pendente.

## Uma rodada útil

- Comece com a recomendação do conjunto e a consequência para a experiência.
- Agrupe normalmente três a cinco decisões independentes do mesmo tema. Ajuste
  esse tamanho à carga de leitura; não transforme o número em uma obrigação.
- Cada pergunta precisa de duas ou três opções distinguíveis, uma recomendação
  explícita, a base dessa recomendação e a principal concessão envolvida.
- Ponha a recomendação primeiro. As opções devem responder à mesma pergunta,
  sem sobreposição; por exemplo, não misture sistema de vida com condição de
  derrota na mesma lista.
- Prefira escolhas de experiência: comandar o grupo, perder um integrante,
  especializar um baralho. Resolva números de custo e microdecisões por proposta
  e protótipo, salvo quando eles expressarem uma preferência central do usuário.
- Dê exemplos concretos de uma jogada ou situação quando esclarecerem a escolha.
- Use `request_user_input_async` quando disponível e continue o trabalho que não
  dependa das respostas. Não repita a rodada no texto final se ela já está visível.
- O usuário pode responder por número, escolher alternativas ou delegar o bloco.
  Recomendação e opção pré-selecionada não são respostas do usuário. Silêncio
  também não confirma uma opção. Preserve a pergunta pendente.

Formato de referência para cada pergunta:

> **1. Tema — decisão concreta.** A: recomendação e efeito. B: alternativa e
> efeito. C: outra direção, se necessária. **Recomendo A porque...**, com o
> princípio de um jogo de referência e a concessão específica do Umbral.

Não acrescente uma pergunta sem opções no fechamento, em um pedido informal de
feedback ou em uma atualização de progresso. Essa preferência vale para toda a
conversa de planejamento.

## Fundamentar sem transformar analogia em prova

Uma recomendação deve identificar:

1. **Princípio observado:** o que a referência realmente faz, com fonte quando
   houver pesquisa ou uma afirmação específica que precise ser verificada.
2. **Aplicação ao Umbral:** como esse princípio ajuda a promessa de criaturas
   marcantes e combinações surpreendentes.
3. **Concessão:** o que fica mais simples, mais difícil ou menos disponível.
4. **Validação:** o que precisamos observar no protótipo ou playtest para manter
   a recomendação.

Exemplos: Balatro distingue modificadores persistentes e consumíveis que editam
o baralho; Pokémon associa poderes e evolução à identidade das criaturas;
PokéRogue inspira formação e adaptação do time durante a run; Slay the Spire
inspira escolhas de consistência, rota e recursos; Monster Train inspira
interações entre unidades e cartas. Essas analogias não comprovam que uma
quantidade de slots, uma economia ou uma regra será divertida no Umbral.

Se houver cálculo, declare as hipóteses. Uma probabilidade de compra não é uma
medida de diversão nem uma validação do balanceamento.

## Autonomia e respostas

- Preserve a intenção já dada. Não pergunte novamente se haverá combate coletivo,
  capacidade expansível ou edição do baralho quando isso já foi estabelecido.
- Quando o usuário delegar recomendações, adote escolhas reversíveis coerentes e
  registre **adotada por delegação**, sem atribuir a ele uma aprovação literal.
- Respostas explícitas confirmam a direção respondida. Não estenda uma resposta
  sobre capacidade do time para inferir vida, quantidade inicial, energia ou
  número de cartas jogáveis.
- Se uma resposta invalidar uma hipótese, atualize as dependências antes de
  formular a próxima rodada. Se uma lista anterior tinha opções sobrepostas,
  preserve a preferência inequívoca e separe a decisão restante.
- Faça contrapontos quando uma escolha prejudicar os pilares: explique o
  problema com um exemplo e apresente alternativas com recomendação.
- Não introduza uma confirmação ritual no fim da entrevista. Continue dentro da
  autorização existente. Planejar autoriza documentos e propostas; mudanças no
  gameplay seguem o escopo da tarefa e o workflow `umbral`.

## Registro e avanço

Atualize a fonte de verdade em `docs/roadmap.md`; sincronize o mapa HTML quando
alterar o contrato proposto, os marcos ou o escopo. Registre IDs de decisão,
justificativas, questões pendentes e a próxima fatia observável. Mantenha a versão
executável e o comportamento atual separados do produto planejado.

Uma rodada termina com direção suficiente para aprofundar a fase atual. Não
entreviste todo o jogo antes de desenvolver a primeira proposta. Use protótipos e
playtests para questões de sensação e ritmo que uma conversa não consegue resolver.
