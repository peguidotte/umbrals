# V04-UX-05A — plano e avaliação da fatia

## Plano antes da edição

Base: main `00ede11`, referência `references/battle/00-aprovada/battle.png`.
Produto permanece 0.3.0. UX tem prioridade sobre V05-ECON-03.

Adotado por delegação para experimentar no runtime: superfícies azul-violeta,
texto claro, cristal violeta para custos e âmbar para confirmar/selecionar.
Naturezas mantêm as cores do catálogo. Não constitui aprovação estética humana.

Estados da mesma batalha (semente de treino 42013, Brasa):

| Estado | Apresentação e critério |
|---|---|
| Planejamento | Dono em retrato, arte maior, potência/custo em primeiro plano; cristais mostram ações livres e comprometidas. Nada é executado ao inspecionar. |
| Cartas/alvos escolhidos | Moldura âmbar e marca de seleção; carta em edição tem indicação própria. Alvo e alcance continuam escritos e destacados no campo. Comandos próprios mostram dono e destino; a ordem depende de velocidade. |
| Execução/resultado | Mão comprometida preservada; evento real no HUD e impacto no ator. Resumo acessível explica danos e reações ocorridos, sem antecipar o plano privado do inimigo. |

O centro e as âncoras dos atores permanecem. Consolidar tokens no kit, aplicar
primeiro à batalha, conferir seu render e só então propagar ao mapa. No mapa,
um bosque com trilhas conectadas e marcos de combate/nascente/guardião substitui
a aparência de colunas de formulário. Detalhes apenas do marco selecionado;
retratos e HP do time continuam visíveis. Selecionar não entra no nó.

Arquivos previstos: `kit.gd`, `power_card.gd`, `battle_hud.gd`, apresentação
de ações em componente próprio, `main.gd` somente na ligação dos dados públicos,
`expedition_map.gd` e um desenho de trilha reutilizável. Nenhuma alteração de
regras, conteúdo, grafo, formato de save ou RNG.

Validação prevista: capturas atuais antes/depois; `tools/iterate.py` completo
com baseline e vídeo; revisão dos estados, 1×1/3×3, texto ampliado, teclado,
toque emulado e matriz. Testes não medem beleza, diversão ou uso em celular
físico. Evidências completas ficam nos diretórios ignorados. A publicação posterior da prévia está registrada abaixo.

## Resultados efetivamente verificados — 31/10/2026

Gate completo aprovado em `artifacts/V04-UX-05A-ready-20261031T000348103949Z`. Produto permanece **0.3.0**;
a aprovação automática não encerra os critérios humanos/visuais do marco.

| Verificação | Resultado |
|---|---|
| Regras de batalha | 14413 verificações, sem falhas |
| Mutações representativas | 8/8 detectadas |
| UI/fluxo/boot | 454 verificações; relatório agregado 666 inclui também 212 de catálogo |
| Expedição/save/cena | 109 verificações, sem falhas |
| Navegador de batalha | 1802 verificações; quatro percursos, 1×1/3×3 e cinco formatos |
| Navegador de expedição | 383 verificações; bifurcação, descanso, conclusão e retomada |
| Capturas do gate | 76 de batalha e 18 de expedição |

Comando: `python tools/iterate.py --label V04-UX-05A-ready --baseline test-results/V04-UX-05A-baseline --step-timeout 3600`.
O limite por etapa foi ampliado para o render por software. Percursos, asserts,
contagens e detecção de mutações não foram reduzidos. Esta tentativa não grava
vídeo contínuo; a captura complementar da batalha de referência tem seu próprio
vídeo, além do vídeo parcial anterior preservado.

O hash das fontes e do PCK Web está em `run.json` / `source-manifest.json`.
A documentação de fechamento foi escrita depois do gate; os arquivos de código
continuam iguais aos arquivados. O fechamento inicial foi local; a prévia privada
foi publicada posteriormente conforme registro abaixo. Não houve push no
repositório do jogo nem CI remoto. Não foram executados Windows, controle físico
ou celular físico.

As capturas atuais da mesma batalha e o mapa estão em
`test-results/V04-UX-05A-reference-ready/` (`index.html`, PNGs, snapshots e
`reference.webm`); o percurso de toque atual está em
`test-results/V04-UX-05A-touch-ready/`. São renders do jogo, não mockups.
A comparação de referência usa os mesmos dois poderes, distinguindo-a das
comparações automáticas entre capturas de percursos com seleções diferentes.

## Implementação

- Kit compartilhado: tinta `#0c1026`, superfície `#141b36`, elevação
  `#242c4c`, borda `#59658f`, cristal `#b5a0fa`, texto `#eeeaf7`,
  secundário `#aab6d5`, confirmação/seleção `#f2bd70`.
- Cartas: arte existente ampliada, custo em cristal, potência em 16 pontos,
  títulos quebrados por palavras em tamanho fixo (sem reduzir até 11), retrato
  e UID do dono. O mesmo UID aparece no ator aliado e no time do mapa.
  Seleção tem moldura/marca; edição tem barra e rótulo ALVO; falta de ações
  tem aviso SEM AÇÕES e custo sinalizado. Isso não impede editar um plano
  acima do orçamento: Conjurar continua bloqueado pelas regras existentes.
- Ações: cristais livres/comprometidos, contagem textual e confirmação âmbar.
  A prévia continua sendo a estimativa pública dos próprios poderes.
- Mãos modificadas: rolagem horizontal e foco automático em vez de comprimir
  todas as cartas; teste de 18 cartas confirma acesso à última e retorno à
  primeira, sem alterar cartas, RNG ou rodada. A verificação de 18 cartas
  cobre largura e foco; não certifica a estética de todas as mãos modificadas.
- Mapa: floresta original reenquadrada no runtime, trilha bifurcada conectada,
  cristais procedurais e marcos com imagens do catálogo. Rótulo de estado em
  cada marco e consequência apenas no selecionado; retratos/HP do time.
  Selecionar continua separado de confirmar. Não há imagem inédita gerada.
- Sem mudanças em rules/content, iniciativa, alvos lógicos, informação
  inimiga, grafo de expedição, storage ou formato de checkpoint.

## Revisão das capturas pela IA

A mesma batalha usa treino 42013 / Brasa: Manto de cinzas e Garra de brasas.
As capturas anteriores e atuais mostram o dono em cada carta, arte maior e
custo destacado. Seleção e edição têm marcas diferentes; o alvo no campo não
invade o corredor central. A captura de execução conserva a mão comprometida;
o resumo discrimina escudo, dano direto e Queima já ocorridos. Os resultados
numéricos da combinação não mudaram.

A primeira composição cortava Plano/Resumo por aumentar a altura do medidor;
as alturas e separações foram corrigidas após inspecionar o render. No mapa,
os painéis inicialmente largos escondiam a bifurcação; foram estreitados e
centralizados. A decoração passou a ficar contida na moldura. O primeiro
padrão de árvores geométricas foi substituído por floresta do catálogo e
cristais, compartilhando melhor o motivo dos custos.

## Tentativas preservadas

- `V04-UX-05A-20261030T232246254126Z`: interrompida para corrigir os problemas
  visuais encontrados; fontes alteradas invalidaram a tentativa. Não é gate
  aprovado.
- `V04-UX-05A-final-20261030T232712134844Z`: regras, oito mutações e UI passaram,
  mas o runner rejeitou erro real de curva de comprimento zero no mapa durante
  rebuild. O desenho agora aguarda centros distintos e uma área válida.
- A checagem local inicial de UI também rejeitou a ausência do texto de ações
  planejadas; a contagem passou a apresentar livres e planejadas explicitamente.
  A asserção original foi preservada.

## Limites e próximo passo

A direção de cor foi adotada por delegação para avaliação, sem atribuir nova
aprovação estética ao usuário. Os desenhos de poderes continuam sendo as
ilustrações vetoriais existentes, e a nascente ainda reutiliza o símbolo de
chuva. Não há catálogo novo de pinturas de poderes/marcos dedicado a esta
fatia. Substituí-los por arte expressiva da mesma família é o próximo passo
artístico; o ganho desta entrega está em hierarquia, identidade e interação.

A apresentação mantém parte dos comandos no alto como na implementação base;
a aproximação deles à confirmação pode ser refinada depois de observar pessoas
jogando. Texto em telas pequenas e reconhecimento dos ícones precisam de
playtest. Emulação não valida celular físico; testes não comprovam beleza,
compreensão humana, diversão, performance em GPU real ou plataforma Windows.
Formação e recompensas herdam o tema, mas não receberam uma reformulação
completa de composição. O mercador permanece posterior. Produto 0.3.0.

### Recomendação para celular (proposta)

| Opção | Benefício | Concessão |
|---|---|---|
| A — HUD compacto, menos cartas simultâneas e rolagem | Custo, efeito e alvos maiores, mantendo a mão e as regras | Exige deslocar a mão para comparar cartas distantes |
| B — Seis cartas simultâneas, ampliando só a inspeção | Mantém toda a mão visível | O texto essencial no campo continua pequeno |

Recomendo A com base nas capturas em 844×390: o toque funciona, mas a leitura
é insuficiente. Trata-se de uma proposta para a próxima fatia de UX, sem nova
aprovação atribuída ao usuário e sem alterar a formação/câmera de PC.

Na captura de execução com vários golpes, os rótulos flutuantes de Queima
ficam próximos do nome/HP do adversário. O resumo continua explicando os eventos,
mas o empilhamento desses textos merece refinamento posterior; não foi criada
uma nova animação ou trocado o VFX nesta fatia. A revisão por amostras do vídeo
parcial encontrou também o crescimento das margens no estado desabilitado;
a correção iguala os estilos e acrescenta seis asserts de geometria. A captura
Web da execução corrigida mostra Plano/Resumo e pilhas inteiros.


### Interrupção e retomada

`V04-UX-05A-verified-20261030T232945399833Z` foi interrompida pelo reinício
do ambiente antes do relatório final Web. O registro reconstruído marca
**interrupted**, preserva 34 capturas e não apresenta o gate como aprovado.
`V04-UX-05A-resumed-20261031T000039314424Z` foi interrompida para corrigir o
crescimento das margens dos botões desabilitados identificado no vídeo.
A tentativa `V04-UX-05A-ready` acima é o gate completo da revisão corrigida.

V04-UX-05A entrega a base jogável avaliada; a aceitação visual completa continua
aberta, especialmente em 844×390. Próxima recomendação: **V04-UX-05B**, HUD
compacto para celular, arte dedicada de poderes/marcos e refinamento dos rótulos
de resultado, antes de V05-ECON-03. As cinco sessões humanas continuam pendentes.

## Publicação da prévia privada — 31/10/2026

A pedido do usuário para visualizar no celular, o Site existente foi atualizado:
https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site
A página `/novidades.html` apresenta quatro capturas reais da fatia atual.
O público privado existente foi preservado. Sites confirmou a publicação com
status `succeeded`, deployment `appgdep_6ae61fdf69ec819199624b8c933d2441`.

Fonte do Site: commit `81fe7a1d47b057cc375a31d1059df9c8e62e1f33`, em checkout
separado do jogo. O PCK é exatamente o validado pelo gate, SHA-256
`75e1e16f7a0d6b5b71722a7ba1d494f078cdbbeb87da69cafa14f70dbe3d22e2`.
Para respeitar o limite por arquivo da hospedagem, o adaptador baixa duas partes,
reconstitui os bytes e verifica SHA-256 antes de entregar ao motor Godot.
Scripts usam identificação da versão para evitar cache antigo.

O adaptador foi exercitado localmente em Chromium com toque emulado 844×390:
planejamento, duas cartas selecionadas, conjuração, resumo e mapa, sem erros
de console. Evidências: `test-results/V04-UX-05A-hosted-adapter/`. O status do
serviço confirma a publicação; não houve teste remoto autenticado nem teste em
celular físico. A limitação de tipografia pequena permanece.
