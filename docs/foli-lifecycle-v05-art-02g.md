# V05-ART-02G — caminhada e incapacitação da Foli

Fatia sobre o draft #18, sem merge. Foli recebe oito poses de caminhada e
quatro de KO reversível. O mesmo indivíduo `moss` entra após a troca confirmada,
permanece caída com HP zero e recupera a postura após um item possuído.
Produto continua 0.3.0; os golpes ainda usam os efeitos anteriores de bosque.

## Fonte e contrato compartilhado

`characters/foli-lifecycle@0.1.0` preserva a candidata de revisão. O release
`1.0.0` selecionado nesta branch é uma cópia revista, com status técnico
`production` e `production_ready: false`. Isso habilita o pin do draft, sem
aprovação humana de arte ou promoção da família. O original RGBA 1448×1086
com metadados está preservado em `review/original.png`. A divisão em células
362×362 e a translação vertical inteira estão em `normalization.json`; não
houve repintura, reamostragem ou alteração criativa dos pixels.

Somente o novo pin `characters/lifecycle-moss` é acrescentado. O retrato e
tracks de `characters/foli-pilot@1.0.0` permanecem imutáveis. O pivô e a escala
se referem ao corpo visível daquele retrato. O lado contrário é espelhado,
sem verso desenhado.

A base de `CreatureLifecycle`, `actor.gd` e `resolution_feedback.gd` vem do
contrato do PR de Brasa (`feat/brasa-asset-pilot`), sem copiar seus assets ou
selecionar seus pins. `creature_rig.gd` prioriza um pin opcional por forma
(`characters/lifecycle-<form_id>`), mantendo `characters/creature-lifecycle`
como fallback compatível. O editor desta fatia é responsável por esses quatro
arquivos, o módulo de Foli, o teste focado e os inventários gerados. Ao combinar
PRs, preservar um único adaptador e as duas famílias de pins.

A revisão independente recusou o crossfade inicial por duplicar cabeças/patas.
O perfil de Foli usa o corte opcional `settle_mode: cut`; o default das outras
criaturas permanece crossfade. A malha invisível deixa de ser reconstruída
enquanto o clip opaco possui o corpo. Há ainda um pequeno salto de postura
no corte, explicitado no [parecer independente](foli-lifecycle-independent-review.md).

## Eventos e compatibilidade

A troca planejada não inicia caminhada. O evento da troca confirmada aplica
o snapshot antes de buscar o ator que entra. Somente a mudança de vivo para
HP zero inicia o KO; o último quadro persiste após o feedback e cancelamento
de movimento. Reanimação do mesmo UID reproduz o KO ao contrário. Pausa
congela o relógio; movimento reduzido preserva o último quadro de KO.

O clip move somente a apresentação. O retângulo alvo, slots, iniciativa,
poderes, inventário, RNG, UID, passivas, evolução e formato de save continuam
nas regras existentes. Não há estado cosmético gravado no save. As fixtures
privadas usam expedição validada e executam comandos reais de produção;
não são setters de navegador nem fixtures exportadas para o produto.

## Evidência real e limites

O preview nativo v3 mostrou o loop e os cortes nas duas orientações e em duas
escalas. O revisor independente deu GO técnico para integrar em draft, com
aprovação estética pendente. Não foi usado como prova de eventos das regras.

A captura separada `artifacts/foli-native-game-lifecycle/` executou os comandos
semânticos de troca, passagem do turno, dano e item na cena real do jogo.
Foram 16 verificações, zero falhas. O log registra UID 1, HP 48 durante a
entrada, HP 0 no KO persistente, HP 17 após reanimação e retorno a idle. Os
PNGs mostram a interface real com HP zero e depois 17. Não houve cliques de
mouse/teclado do sistema nessa captura. `user://` foi isolado antes de iniciar
o processo, sem sobrescrever saves do usuário.

O MP4 nativo contém 303 quadros em 18,08 s, 1280×720, sem interpolação nem
áudio (driver Dummy). As 362 leituras do framebuffer são amostras, não frames
produzidos pelo jogo. Na cena completa, após a marca de entrada, o motor
produziu aproximadamente 8,4 fps; p95 do intervalo de parede ~219 ms e máximo
~1423 ms. A captura tem intervalos não uniformes, p95 ~148 ms e máximo
~621 ms. A origem dessa lentidão não foi isolada; **fluidez da batalha segue
pendente**. O preview controlado mais rápido não substitui esse resultado.

O fechamento focado `foli-lifecycle-final` passou: arquitetura, 71 releases e
202 arquivos imutáveis, 443 checks de catálogo de assets, 85 de movimento e
86 de save. Fontes antes/depois iguais; cobertura explicitamente focada,
sem aceitação integral. A revisão independente da captura real confirmou
caminhada, HP 0 → 17 e UID 1, sem duplicação do corpo. Os relatórios ficam na
entrega de evidências. A CI verde do #18 é histórica para a fatia anterior; não
valida estes novos arquivos. A aceitação da combinação com a candidata
também exige execução própria, sem extrapolar a CI de uma branch isolada.
Os timeouts locais anteriores de mutação e canvas permanecem preservados:
a CI exata do #18 passou, mas a causa local não foi provada e nenhum timeout,
assert ou clique foi relaxado.

## Próximas fatias

Faltam revisão estética e transições mais próximas do idle, verso desenhado,
ataques de folhas-lâminas próprios e desempenho comprovado em hardware alvo.
Folife tinha recorte e estudo de poses em staging. O diagnóstico inicial de
franja vermelha foi corrigido na [fatia seguinte](folife-pilot-v05-art-02h.md):
o filtro contava marrom legítimo. Na entrega desta fatia ela ainda usa a arte
antiga no jogo. Foslash
e Folivel continuam referências/conceitos aprovados, sem forma final jogável
ou regra definitiva inventada por esta entrega.
