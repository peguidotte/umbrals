# Revisão tática da batalha — V04-BAT-02A

Objetivo: tornar planejar, revisar e responder às ameaças mais interessante,
mantendo o campo opcional de um a três, seis no elenco, mão base seis, três
ações compartilhadas e a composição visual aprovada. Esta fatia continua no
marco 0.4; a versão de produto permanece 0.3.0.

## Diagnóstico e mudanças

O percurso anterior podia terminar sem receber dano: a heurística existente
venceu as 100 sementes sem sofrer um ataque. Preparo era uma ação vazia, e HP
baixo permitia eliminar adversários antes de sua primeira resposta. Alvos e
máscaras tinham implementações duplicadas; mudar um alvo reconstruía a mão
porque seu fingerprint incluía o alvo transitório. Trocas e itens planejados
eram pouco visíveis fora dos respectivos diálogos.

- Preparo agora acumula Carga visível, consumida pelo próximo ataque, inclusive
  em área. Derrotar quem prepara impede sua ação; defender ou concentrar dano
  ganha valor. A potência exata continua restrita ao modo completo.
- HP e padrões dos três encontros foram revistos. Alguns ataques individuais
  procuram o ativo com menor HP no momento de comprometer o plano. A IA não
  consulta a seleção futura do jogador nem refaz seu alvo durante a rodada.
- O painel Plano permite rever comandos, escolher alvos individuais pelo nome,
  retirar poderes/trocas/itens e limpar tudo gratuitamente. Mostra apenas os
  comandos do jogador por prioridade/velocidade, com aviso de empates e da
  intercalação adversária. Notas de água/raio descrevem condições, sem prometer
  um resultado nem simular o plano inimigo.
- Q/E alternam entre alvos válidos; a carta sob foco/mouse passa a orientar a
  mira quando já selecionada. Anéis no chão distinguem opções e área escolhida.
  Um clique no lado inválido explica o problema, sem abrir outra tela.
- P/LB abre o plano; Backspace limpa os comandos; a navegação por foco permite
  as mesmas edições com controle. Compra/descarte são consultáveis, agrupados
  por dono/técnica sem revelar a ordem da pilha de compra.
- Cartas e inspeção usam a mesma avaliação de traits/passivas das regras.
  Alterar um alvo conserva os nós das cartas. Itens/entradas já reservados ficam
  indisponíveis com o motivo usado pela própria regra.
- O seletor inicia a navegação no alvo atual e usa a paleta do jogo. Durante
  feedback, inspeção não consulta o HP já avançado do modelo e alterações no
  tamanho de texto só reconstroem a tela ao terminar a sequência comprometida.

## Arquitetura para expansão

`rules.gd` continua sendo a entrada pública e dona do estado da batalha. Três
colaboradores puros em `scripts/battle/` removem responsabilidades específicas:

| Módulo | Responsabilidade e contrato |
|---|---|
| `targeting.gd` | Máscaras, vagas e opções válidas; usado pela execução, validação e seletores. Sem estado de cena/RNG. |
| `initiative.gd` | Construção dos comandos do jogador e fila comprometida; uma ordenação por prioridade/velocidade, desempates canônicos com RNG apenas ao executar. |
| `enemy_planner.gd` | Padrões e políticas de alvo baseadas na formação atual; compromete uma vez por rodada com o RNG da run. |

`ui/battle_hud.gd` monta a composição e emite comandos sem acessar regras.
`ui/battle_plan.gd` apresenta/edita uma projeção recebida; não recebe o plano
inimigo. `main.gd` coordena a sessão, encaminha comandos e apresenta eventos.
Consumíveis e suas quantidades/custos/efeitos agora ficam no catálogo junto aos
outros dados; tipos desconhecidos são rejeitados. Não foi criado um framework
genérico de plugins/efeitos.

## Critérios de aceitação

1. Revisar, editar e limpar comandos sem gastar recursos ou alterar RNG; mudar
   alvos sem reconstruir cartas; foco e retorno funcionam nos novos painéis.
2. Usar os mesmos alcances ao destacar, validar e executar, incluindo próprias
   defesas, vagas vazias e técnicas com máscaras fixas.
3. Preparo produz condição real, modifica somente o próximo ataque e respeita
   defesa, áreas, nocaute e os níveis de informação.
4. Regressões de identidade, baralho, troca, reanimação, iniciativa e visibilidade
   passam; duas rotas reais e a matriz de cinco formatos são exercitadas.
5. Comparar as mesmas políticas antes/depois, registrar renders e rever vídeo.
   Não confundir heurísticas com avaliação humana de diversão/dificuldade.

## Medição reproduzível

`tests/battle_balance_probe.gd` compara sementes 0–99 usando três políticas.
As políticas não usam consumíveis nem editam alvos manualmente; a política
aleatória usa RNG separado do jogo. Os números abaixo medem o percurso todo,
incluindo dano absorvido entre vários integrantes, e não um HP compartilhado.

| Política (100 sementes cada) | Vitórias antes → depois | Dano recebido médio antes → depois | Rodadas médias antes → depois | Nocautes totais antes → depois |
|---|---|---|---|---|
| Heurística existente | 100 → 100 | 0 → 12,85 | 6,26 → 8,77 | 0 → 0 |
| Heurística que coloca capturas em campo | 100 → 100 | 28,31 → 82,05 | 8,27 → 11,64 | 0 → 51 |
| Subconjuntos legais aleatórios com capturas em campo | 100 → 68 | 41,59 → 125,46 | 14,71 → 24,15 | 0 → 177 |

O resultado indica respostas adversárias e maior custo de decisões aleatórias,
com os percursos heurísticos ainda vencíveis. Não estabelece a taxa desejada
para humanos, equilíbrio de especialização/cooperatividade ou dificuldade final.

## Validação e próximos limites

Validação local aprovada em `V04-BAT-02A-accepted-check-20261027T041626248117Z`, fonte
`7adf0bd9988032ef83f0ab1f5a482880c97740200004eb0382bcea72b4b1375c`:

- 12197 verificações de regras; 100 percursos heurísticos sem deadlock.
- 63 verificações de preferências, foco, input e inicialização; inclui
  navegação do popup e adiamento de reconstrução durante feedback.
- Duas mutações comportamentais detectadas, sem crashes usados como aprovação.
- 1005 verificações no navegador por controles reais; duas rotas, seleção
  pelo menu, retirada de poderes/trocas/itens, captura/evolução e 3×3 real.
- Cinco formatos com texto ampliado e editor do plano; capturas, snapshots e vídeo
  preservados em `review.html`/`review-bundle.zip` da rodada.
- Web/Linux/Windows exportados; startup/encerramento Linux headless aprovado.
  Windows foi exportado, sem execução real nesse sistema.

A revisão visual está registrada em `review-notes.json`. As tentativas anteriores
foram preservadas: interrupções identificadas, um caso de máscara vazia corrigido
e uma falha de sincronização/navegação do popup. A versão final passou com fontes
congeladas. Atualizações posteriores restringem-se a documentação/evidência;
`post-validation-docs-and-package.json` registra a conferência.

Nenhum teste automático foi tratado como aprovação humana, desempenho de hardware
ou demonstração de diversão.

Permanecem: cinco primeiras sessões observadas, ajuste por comportamento humano,
seleção de starter, remapeamento, animações de poses, novos poderes/relíquias e
aprendizado/lojas. O coordenador ainda contém diálogos de progressão e pode ser
dividido por tela nas próximas fatias; esta revisão separa a composição e o
planejamento de batalha sem reescrever todo o projeto.
