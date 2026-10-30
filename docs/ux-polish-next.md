# Próxima fatia: V04-UX-05A — batalha de referência

Prioridade revisada pelo usuário em 30/10/2026: dedicar o próximo incremento à
UX e ao acabamento visual antes de V05-ECON-03. Este documento é um plano;
nenhum redesign foi implementado ou publicado nesta rodada. Produto 0.3.0.

## Resultado que buscamos

Uma batalha coerente com a composição já aprovada, em que seja fácil reconhecer
de quem é cada carta, o que está selecionado, quais vagas serão atingidas,
quantas ações restam e o que aconteceu na conjuração. Usar uma batalha como
referência de acabamento antes de espalhar componentes pelas outras telas.

A referência continua em [00-aprovada](references/battle/00-aprovada/README.md):
2D simples, câmera horizontal elevada, chão coerente, centro livre para golpes
e HUD na ordem reservas → cartas → ações → mochila/pilhas. Não reabrir câmera,
3×3, seis integrantes ou a mecânica de cartas. Os gráficos da referência são
orientação visual, não catálogo ou screenshot do executável.

## Direção confirmada: mais imagem e identidade própria

O usuário reforçou excesso de texto, pouca imagem no mapa e pouca identidade
nas cores/apresentação do HUD. Essa orientação passa a ser requisito do redesign
(D45). Paleta, motivos e soluções abaixo são recomendações de execução, não
aprovação literal de uma arte nova.

| Superfície | Direção proposta |
|---|---|
| Mapa | Bosque ilustrado com uma trilha e marcos reconhecíveis: combate, nascente e guardião. Conexões e estados mostram o percurso. Selecionar um marco revela uma descrição curta e sua consequência; não manter descrições de todos os caminhos abertas. O grafo inicial continua o mesmo. |
| Time e reservas | Retratos/sprites com barras de HP e indicadores de campo/reserva. Identificar indivíduos da mesma espécie com nome curto ou outro sinal legível; o retrato sozinho não distingue duas capturas iguais. Formação continua opcional até três ativos e seis integrantes totais. |
| Cartas | Ilustração do poder em destaque, custo e valor principal fáceis de ler, retrato do dono e máscara visual de alcance. Nome curto visível; explicação de condição/reação e números secundários na inspeção por clique/toque/foco. Não substituir tudo por ícones genéricos. |
| Ações e pilhas | Marcadores visuais de ações disponíveis/gastas, acompanhando a capacidade real. Mochila e pilhas usam ícones próprios e contadores. Conjurar mantém rótulo claro; Resortear comunica a consequência de passar a rodada. |
| HUD dos integrantes | Nome e HP compactos, condições com ícones próprios e contadores, intenção com símbolos e apenas a informação permitida pelo modo. Atributos e descrições extensas ficam acessíveis ao selecionar/inspecionar. |

Recomendação de identidade: pixel art limpa, base noturna azul-violeta ligada ao
bosque/cristais da referência, texto claro e acento âmbar para a ação principal.
Molduras e ícones autorais discretos dão personalidade. Reservar cores de
naturezas/condições para significados consistentes; evitar espalhar a cor da
espécie por todos os textos e painéis. Usar materiais, formas e contraste, além
de cor, para distinguir seleção, alvo e estado bloqueado. Não prometer a paleta
como escolhida antes de vê-la em composição.

Menos texto permanente exige mais qualidade de imagem e de interação: orçamento
de ilustrações de poderes, retratos reutilizados do catálogo e marcos do mapa.
Informação crítica permanece visível; detalhes precisam funcionar por toque e
teclado, não só por hover. Ícones novos recebem rótulos contextuais e podem ter
legenda curta na primeira apresentação. Não reduzir fontes para caber nem
eliminar a explicação de combos para produzir uma tela aparentemente limpa.

## Base da recomendação

Revisão de código e referência aprovada, sem nova auditoria visual. A ferramenta
de captura de navegador não está disponível nesta sessão. Capturas antigas não
foram usadas como se pertencessem a uma nova auditoria. Uma implementação deve
ser avaliada por capturas atuais e interação real antes de ser aceita.

- `scripts/ui/kit.gd` já fornece fontes, paleta e tema. `battle_hud.gd` e
  `expedition_map.gd` acrescentam estilos próprios: consolidar essa base existente.
- `power_card.gd` desenha custo, natureza, arte, título, potência, alcance e dono.
  Vários textos secundários ficam limitados a 12–14 pontos e o título pode
  encolher até 11. Definir prioridade e detalhes sob demanda antes de reduzir
  mais a fonte para caber.
- `battle_hud.gd` separa comandos no alto, instruções/prévia acima da mão e
  ações no rodapé. A próxima proposta deve aproximar decisão e confirmação,
  preservando o centro do campo e a composição aprovada.
- O mapa usa colunas e painéis de informações. A etapa seguinte deve comunicar
  percurso, escolha e consequência com mais presença do bosque e menos texto
  permanente; sem alterar o grafo ou a política do save.

## Ordem de trabalho

1. **Linguagem visual e uma batalha de referência.** Definir tipografia,
   hierarquia, espaçamento, bordas, ícones e superfícies para o kit existente.
   Cartas e HUD devem combinar com as criaturas em pixel art. Fontes de leitura
   não precisam imitar pixel art se isso prejudicar a legibilidade.
2. **Planejar, mirar e conjurar.** Tornar distintos foco/hover, selecionada,
   carta em edição de alvo, comando planejado, bloqueada e indisponível por
   ações. Dar presença ao dono e ao custo; mostrar mais detalhes ao inspecionar.
   Comandos compactos, ações restantes e confirmação devem formar um conjunto
   fácil de acompanhar. Clique não passa a definir a ordem de execução.
3. **Entender o resultado.** Destaque breve do ator/impacto, condições e reação
   com nome consistente. O resumo explica o combo ou o motivo de não ocorrer.
   Não adicionar efeitos que escondam criaturas, alvos ou cartas.
4. **Propagar o padrão.** Depois de avaliar a batalha, aplicar componentes ao
   mapa, formação, captura/evolução e diálogos. Tornar caminhos e escolhas mais
   visuais, com retratos/HP e confirmação claros. O mercador vem depois dessa
   base, reutilizando os componentes.

Balatro inspira hierarquia das cartas e resposta imediata à seleção; Pokémon,
presença e identidade dos integrantes; Slay the Spire/Pirates Outlaws, leitura
de custos, intenção e consequências. São princípios para o Umbral, não prova
de que um layout ou efeito será bom sem testar.

## Primeira entrega concreta

Uma proposta visual da **mesma batalha** em três estados: planejamento vazio,
cartas/alvo escolhidos e resolução/resultado de uma combinação. O mesmo padrão
deve comportar 1×1 e 3×3 e ser avaliado em PC e celular horizontal. São estados
de uma direção já aprovada, não uma nova votação entre três câmeras.

Acompanhar com uma proposta do mapa ilustrado usando a mesma paleta, ícones e
retratos. Ela mostra como a informação sai dos painéis permanentes e passa a
ser comunicada pelo percurso e pela seleção, sem mudar o grafo ou suas regras.

Depois, implementar e comparar os mesmos estados no jogo. Não encerrar a fatia
com apenas um conceito bonito. Preservar texto ampliado, foco/teclado, toque,
movimento reduzido e a acomodação da mão modificável.

Critérios observáveis:

- Dono, custo, seleção, alvo e ações restantes reconhecíveis sem abrir um painel.
- Cancelar/editar não conjura, troca, compra ou sorteia; retorno de modais mantém
  contexto. Resortear comunica que passa a rodada e recebe ataques.
- Alvos próprios e condições legíveis sem depender somente de cor. Não revelar
  intenção/alvo inimigos ocultos nem um futuro HP que a informação não permite.
- UI não garante água antes de raio; iniciativa e interferências continuam
  valendo. Uma combinação potencial é comunicada de forma condicional.
- Regressões, screenshots atuais e revisão dos trechos de animação passam.
  Primeiras sessões humanas avaliam compreensão; contagem de testes não mede
  beleza ou diversão. Celular físico não é validado por emulação.

## Paralelização

Fixar primeiro os estados/componentes visuais. Depois: uma frente mantém tema,
cartas e ícones; outra, apresentação dos comandos/alvos; outra, jornadas e QA.
Um integrador mantém a composição do HUD e as interfaces compartilhadas. Não
editar `kit.gd` ou o mesmo componente em múltiplas frentes ao mesmo tempo.
Mapa/recompensas entram quando essa base estiver utilizável, evitando estilos
diferentes sendo inventados em paralelo. Não alterar regras para simplificar UI.
