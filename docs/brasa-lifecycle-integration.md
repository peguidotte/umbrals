# V05-ART-01C — Brasa com locomoção, KO e reanimação

Continuação da [primeira fatia](brasa-pilot-v05-art-01b.md). O blocking rejeitado
0.1.0 permanece intacto. O piloto usa somente `ember`, sem renomear IDs, alterar
conteúdo mecânico, saves, naturezas ou produzir o final de fogo. Sendral continua
aprovado; a proposta do final quadrúpede/três caudas/juba menor aguarda validação.

## Recursos e reprodução

`characters/brasa-lifecycle@0.2.0` guarda o estudo novo: oito poses de caminhada
e quatro de KO, geradas com o Brasa existente como referência. O PNG original
fica em `review/`, com hash e proveniência. A normalização só recorta células
e translada pixels inteiros para alinhar a linha de chão; não redimensiona
nem repinta a fonte. A [revisão nativa a 118 px e 3×](brasa-lifecycle-native-review.md)
antecede a cópia para `1.0.0`, selecionada explicitamente para integração nesta
branch. Aprovação visual independente segue pendente; a metadata não anuncia
`production_ready` nem aprovação estética de Pedro.

| Estado | Fonte e comportamento |
|---|---|
| Repouso | `battle-motion@1.0.0`, `states/0`, pixels existentes |
| Preparação | `states/1`, existente |
| Conjuração | `states/2`, quinze casts e seus sockets/relógios existentes |
| Dano | `states/3` e reações existentes |
| Defesa | `states/4`, existente |
| Celebração | `states/5`, existente; não representa KO |
| Locomoção | `brasa-lifecycle@1.0.0`, oito poses/10 FPS, entrada visual com avanço do corpo |
| Incapacitação | Quatro poses, baixa/apóia/deita e mantém o último quadro |
| Reanimação | O item/regra atual restaura HP; a apresentação libera KO e volta aos estados existentes |

O pin novo `characters/creature-lifecycle` é aditivo. Os pins de ataques,
arte estática e motion publicados permanecem idênticos. A seleção por forma
fica no JSON do módulo; o renderer não tem branches de espécie.

`ui/creature_lifecycle.gd` possui os clips cosméticos. O rig de produção mantém
malha, sockets e casts. A caminhada começa no evento de troca **confirmada**,
incluindo entrada em vaga vazia; planejar, cancelar ou reconstruir uma tela
não dispara locomoção. Só a apresentação se desloca, não o slot/hit area.
Uma conjuração interrompe o walk. Pausa congela o relógio e movimento reduzido
remove a entrada, mostrando diretamente a pose final de KO. Cancelamento não
ergue um incapacitado. Carregar um checkpoint já incapacitado começa na pose
final, sem repetir a queda. Reanimar preserva UID/passiva/cartas e libera o KO.

## Validação e evidências

O teste `battle-motion` passou com 53 verificações na primeira integração,
incluindo uma troca real, avanço de quadro/posição com hit area fixa, pausa,
KO por dano, pose mantida após cancelamento, movimento reduzido, reanimação
por item e RNG preservado. A fixture `brasa_lifecycle` é um checkpoint validado
e exclusivo dos testes; o export de produção continua excluindo boot e dados
de fixtures. Não há setters na bridge pública. Os ajustes posteriores e a
base sincronizada passam por nova execução antes do fechamento.

`capture_integrated.py` usa cliques reais em reserva, slot, Conjurar, continuar
após KO, mochila e item. Grava canvas e áudio real do jogo. A captura de estudo
em `artifacts/brasa-lifecycle-game-retry-20261104T2344Z/` mostra passos distintos
e avanço do corpo, KO legível a 118 px e retorno após reanimação. A versão anterior
preserva uma falha na extração do vídeo; as imagens daquela tentativa não são
substitutas de um vídeo bem-sucedido. `capture_battle_performances.py --forms ember`
revisa separadamente os três casts já existentes por poderes possuídos reais.

Há variação no ritmo dos passos e na cauda entre desenhos. Esta é uma animação
de poses geradas, não animação manual. A revisão independente deve avaliar
fluidez, apoio dos pés e transição ao repouso usando o vídeo inteiro. Testes
numéricos e quadros diferentes não são um selo de qualidade. O KO mantém o
tratamento visual de incapacitação existente e não representa morte definitiva.

Comandos da continuação:

```bash
python tools/assets.py validate --base-ref origin/main
python tools/harness.py check --suite battle-motion,fixtures,assets,asset-unit
python tools/harness.py check --suite web-fixtures,packed-fixtures
python tools/brasa_pilot/capture_integrated.py --build-dir <fixture-build> --output <artifacts-review>
python tools/capture_battle_performances.py --build-dir <fixture-build> --output <cast-review> --forms ember
python tools/iterate.py --label brasa-lifecycle --goal 'Brasa entra com passos, cai em KO e volta após reanimação' --video
```

## Referências e integração

A segunda tentativa oficial das três referências também falhou antes da
instalação. Os [registros de Brasa](references/creatures/brasa/README.md) e do
[mineral futuro](references/creatures/future-mineral/README.md) têm as tentativas;
continuam **sem PNGs locais**, sem rotas alternativas. Os assets desta fatia
derivam do Brasa que já estava no repositório, não de uma reconstrução de Sendral.

A PR #9 foi incorporada pela main durante esta continuação. Seu contrato v1
de tracks normalizados e exemplo histórico ficam preservados. Ele não valida
SpriteFrames; não renomeamos um cast para passar esse gate. Os novos clips são
verificados pelo pipeline de módulos, importador, consumidor nativo e testes de
eventos. Um adaptador de autoria que componha sprites e tracks pode vir depois.

Entrega somente em branch/PR de rascunho. O integrador revisa as mudanças em
rig/ator/feedback, pin/inventários gerados e registra V05-ART-01C no roadmap e
harness compartilhados ao integrar. Não fazer merge antes da revisão independente
e do CI terminal da revisão final. A versão do produto continua 0.3.0.
