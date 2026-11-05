# V05-ART-02F — Foli com arte e rig próprios

Continuação de [V04-CNT-01A](grass-family-v04-cnt-01a.md), sobre o PR #14
`8597f5a`, cuja base é a main `1523d0e`. Produto continua 0.3.0. Rascunho
para revisão, sem merge. Remove um bloqueio visual da integração das famílias;
não encerra a linhagem nem o marco de conteúdo.

## Resultado e fontes

Foli usa um recorte transparente novo, derivado da inicial à esquerda da
referência aprovada. Mantém as duas orelhas de folha, pelagem marrom/oliva,
patas e peito claros, olho âmbar, cauda de folha e três folhas destacadas.
Os pixels do PNG gerado permanecem intactos. A imagem e os estados são do
piloto, com revisão estética de Pedro ainda pendente.

As duas referências foram materializadas neste executor pelo fluxo oficial
da Library e inspecionadas visualmente antes da produção. Originais e hashes
ficam em [referências de Foli](references/creatures/foli/README.md). A v13 é
a Folivel alternativa aprovada com lâminas nos quatro membros; não foi
usada como inicial nem apresentada como forma jogável.

`characters/foli-pilot@1.0.0` contém a imagem RGBA 1254×1254, anatomia,
pivô/pegada e tracks próprios a 30 amostras/s. Não copia o rig da criatura
vegetal anterior. Respiração, orelhas, cauda, patas dianteiras e folhas se
movem por malha; preparação, defesa, dano, recuperação e três casts de
bosque seguem os relógios dos efeitos existentes. Os efeitos e sons de
bosque anteriores são reutilizados; não são novos golpes aprovados de folhas.

## Contratos e integração paralela

Editor desta fatia: módulo `characters/foli-pilot`, gerador em staging,
referências e documentação de Foli, `battle_art.gd`, `battle_motion.gd`,
condição de imagem em `codex/gallery.gd`, suporte de teste e sua chamada em
`battle_motion_test.gd`. Os três inventários gerados seguem o pipeline.
O pin editado é somente `umbrals/moss`; preserve as demais alterações de
outros PRs ao integrar. O rig/ator compartilhado não foi editado.

A interface aditiva é `manifest.metadata.battle_profile`:

- `grounding`: `foot`, `width` e `visible_top` em pixels da imagem original;
- `motion_role`: papel JSON do mesmo release, no contrato `battle-motion-v1`.

`BattleArt` dá prioridade ao pin explícito antes do cache dos atlas antigos.
O cache novo usa a chave completa do binding, evitando que a carga de outro
atlas sobrescreva Foli. A galeria usa o retrato atual em vez da placa pintada
com a criatura antiga. `Motion.form()` lê e guarda apenas o override da forma
declarada; as outras formas permanecem separadas. O fallback material de
inimigos mantém os tracks históricos, sem herdar a substituição da Foli.

Espécie `moss`, formas `moss`/`verdalio`, aresta `moss_to_verdalio`, UID,
passiva, natureza, atributos, resistências, poderes, cópias, descobertas e
save permanecem os mesmos. Não muda regras, catálogo mecânico, RNG,
ruleset, schema de save, coordenadores, registry do harness ou baseline.
O status técnico `production` permite selecionar o release no runtime;
não atribui aprovação visual à imagem ou completude de animação.

## Verificação e evidências

Preflight com fetch: branch um commit à frente, zero atrás da main atual.
Catálogo e save passaram antes da edição em `foli-before`. O pipeline
validou 69 releases/192 arquivos e a imutabilidade contra `origin/main`.
O perfil de autoria é válido e **incompleto**, com caminhada declarada ausente.

A tentativa `foli-pilot-focused` detectou que o atlas carregado antes do
override podia continuar exibindo a arte antiga. A correção preservou o teste.
`foli-pilot-capture-build` passou os 68 checks de movimento e o export isolado
de fixtures. Inclui cast real de Foli, emissão dos três sockets dos dois
lados, apoio, pausa, cancelamento, recuperação e RNG preservado. Save de
expedição, história do grimório, arquitetura e assets também passaram nos
alvos focados. Nenhum desses resultados é aceitação integral. Uma primeira
execução integral foi interrompida voluntariamente antes do navegador para
isolar o fallback de inimigos; foi preservada como interrompida. O teste novo
de isolamento é adicional aos 68 checks anteriores.

Captura dedicada: `artifacts/foli-pilot-capture-20261105/`, com três turnos
por cliques reais. MP4 H264/AAC, 1600×900, áudio real do jogo; 82 quadros em
34,699 s de vídeo, contêiner de 36,529 s. A baixa cadência (~2,36 fps)
comprova estados/eventos, não fluidez. Três screenshots foram preservados.
O fechamento integral usa `iterate.py --video`; resultados, hashes e revisão
dos renders ficam no PR e nas evidências locais dessa execução. Falhas
anteriores não foram removidas e nenhum clique ganhou retry.

## Lacunas

Não há caminhada de membros, frames desenhados por pose ou KO persistente
próprio. O lado oposto é o espelho da mesma arte, não outra vista desenhada.
O rig usa deformação suave de uma imagem; não equivale a animação quadro a
quadro. As três folhas do recorte são animadas em grupo, sem física individual.
Folife ainda usa a arte antiga; Foslash/Folivel não possuem formas ou arestas
jogáveis nesta fatia. Variação de tamanho das lâminas de Folivel e novas
regras precisam de fatia própria e compatibilidade auditada. Performance,
controle físico e revisão gráfica em Windows continuam não verificados.
