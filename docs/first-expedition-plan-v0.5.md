# Próxima entrega — primeira expedição

Estado em 30/10/2026: **V05-RUN-01 e V05-SAVE-02 integradas e validadas localmente**. A batalha
tem fechamento técnico em V04-BAT-04A/B; o produto continua **0.3.0**. Os
critérios humanos de 0.4 permanecem abertos e podem avançar em paralelo.

## O que já está resolvido na batalha

Formação opcional até 3×3, seis integrantes, HP individual, ações, iniciativa,
alvos por posição, cartas com dono, compra/descarte, troca, captura, evolução,
nocaute, reanimação, consumíveis e informação inimiga estão implementados.
As quatro reações e resistências específicas também estão jogáveis.

Não há uma entrevista estrutural da batalha bloqueando a próxima entrega.
Balanceamento, descoberta dos combos, clareza dos comandos e acabamento ainda
precisam de playtest. Limites e aquisição de novos modificadores, técnicas,
relíquias e artefatos pertencem ao conteúdo que será integrado à expedição.
Resgatar/sepultar e ecos narrativos continuam futuros; não são requisitos
pendentes da resolução de um turno. Ver [fechamento e evidências](battle-closeout-v0.4.md).

## V05-RUN-01 — sair da sequência fixa e escolher uma rota

**Resultado observável:** começar com um Umbral, escolher um caminho no bosque,
resolver encontros/recompensas, carregar as consequências para o próximo nó e
chegar a um chefe com vitória ou derrota da expedição.

O incremento reutiliza o bioma, as quatro espécies e os encontros existentes.
O mapa tem uma bifurcação fixa entre outro combate com recompensa e descanso
limitado sem aquela recompensa. A cura de 25% do HP máximo dos vivos é default
adotado por delegação, sujeito a playtest. Loja, eventos variados e expansão do
catálogo não fazem parte desta fatia.

No treino, `choose_reward()` conserva o percurso sequencial anterior. Na
expedição, o controlador agora é responsável pela rota e por iniciar encontros
com IDs de catálogo. Escolher uma recompensa volta ao mapa; não inicia o
próximo combate automaticamente. Ver [contrato implementado](expedition-contract-v0.5.md).

Contrato usado para dividir a implementação:

- Estado de expedição separado do perfil: semente/estado dos RNGs, mapa,
  nó atual, nós acessíveis/concluídos, integrantes/UIDs, composição de cartas,
  formação, HP, inventário, modificadores e ofertas já sorteadas.
- Modelos de encontro/recompensa por ID, independentes da posição no array.
  A batalha recebe o encontro escolhido e devolve um resultado público.
- Operações para consultar o mapa, escolher um nó acessível e concluir um nó
  uma única vez. Consulta, voltar e cancelamento não sorteiam novamente.
- Donos e instâncias continuam pertencendo ao time. A passagem ao mapa não
  recria poderes, cura todos, preenche o trio ou apaga incapacitados por padrão.
- Novos módulos ficam em uma camada de expedição; nenhuma cena decide regras
  de rota, sorteia ofertas ou escreve diretamente no estado da batalha.

São defaults de implementação adotados por delegação, não novas respostas
literais do usuário. O schema é versionado; validação integrada concluída.

Aceitação de V05-RUN-01:

1. Menu → vínculo → mapa → encontro → recompensa → mapa → chefe → resultado,
   por controles reais; as duas rotas da bifurcação são exercitadas.
2. Escolhas alteram recursos/recompensas de maneira visível. Uma mesma semente
   e decisões reproduzem o percurso; consultar o mapa não muda o RNG.
3. Não é possível entrar em nó inacessível, concluir/recompensar duas vezes,
   nem voltar a um nó concluído para farmar.
4. Identidade, HP, reserva, evolução, inventário e cópias editadas sobrevivem às
   transições. Todas as regressões de batalha continuam passando.

## Ordem de integração do restante de 0.5

| Fatia | Entrega concreta | Dependência |
|---|---|---|
| V05-RUN-01 | Estado de expedição + mapa ramificado + ida/volta da batalha | Integrada e validada |
| V05-SAVE-02 | Salvar/continuar a expedição com schema e escrita segura | Integrada em paralelo ao mapa; validada localmente |
| V05-ECON-03 | Primeira construção de build fora da captura: mercador, edição de cópias e primeiras relíquias adquiríveis | Transações e recompensas da expedição; depois decidir custos/ofertas em protótipo |
| V05-CONTENT-04 | Eventos, variedade de rotas e ritmo do bioma | Loop e economia funcionando; medir o alvo de 15–20 minutos |

SAVE-02 salva o estado estável exato após entrada, rodada e recompensa/rest,
incluindo mão, zonas, RNG e intenção já comprometida. Retomar não reinicia
animações nem refaz sorteios; comandos não conjurados são limpos. O save usa
registros versionados, checksum e recuperação. Novo jogo exige confirmação
quando há progresso anterior; treino é separado. A entrega não conclui todos
os critérios de conteúdo/economia do marco 0.5.

Loja durante a expedição e loja do Refúgio entre runs são sistemas distintos.
A persistência das compras do Refúgio (D20) continua aberta para 0.6; não criar
ganho permanente de atributos ou conservar o mesmo time entre novas runs.

## O que pode andar em paralelo

| Frente | Pode começar quando | Limite de responsabilidade |
|---|---|---|
| Estado/fluxo da expedição | Na execução de RUN-01, começando pelo contrato | Contrato de estado, navegação/resultado, adaptação da fachada de batalha |
| Tela do mapa | Após fixar snapshot público, IDs e comandos do mapa | Apresentação/foco, sem RNG ou lógica de acesso; usa fixtures no início |
| Save/continuar | Após fixar schema e política de checkpoint | Serialização, validação/migração e recuperação; preserva preferências/estatísticas existentes |
| UX da batalha e cinco primeiras sessões | Agora | Clareza, tutorial contextual, descoberta dos combos e registro do playtest; preservar regras estabelecidas |
| Preparação de conteúdo/economia | Agora para propostas e dados de teste | Risco/recompensa, ofertas e efeitos; integração depende do loop e das transações |

Um integrador deve ser o dono das mudanças em `scripts/main.gd`,
`scripts/rules.gd` e da assinatura do estado. Evitar múltiplos agentes editando
esses arquivos simultaneamente. A UI do mapa e o save podem ter módulos/testes
próprios; dependências devem ser comunicadas por contrato, não por estado oculto.
Ao final, executar um percurso integrado com os módulos reais — fixtures de
uma frente isolada não comprovam uma expedição jogável.

Não é necessário esperar os cinco playtests para começar a camada de expedição.
Eles continuam necessários para concluir o marco 0.4; não bloquear trabalho
independente de 0.5 nem declarar 0.4 concluído sem essa evidência.

## Por que priorizar isso

Slay the Spire inspira a escolha de caminho como gestão de risco e recursos;
PokéRogue inspira o valor de formar/proteger o time ao longo de encontros;
Balatro inspira especialização por recompensas e consistência do baralho.
São referências de design, não pesquisa nova nem prova de diversão.

No Umbral, a expedição cria o contexto para avaliar captura versus evolução,
cura versus risco e solo versus cooperação. A concessão é adiar novos tipos e
dezenas de golpes enquanto medimos o que as combinações atuais acrescentam
à run. Voltamos a ampliar o combate a partir dessas necessidades observadas.
