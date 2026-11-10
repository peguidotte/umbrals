# V05-CARD-02 — composição modular no jogo, prévia de desenvolvimento

**Revisão posterior de Pedro:** o piloto foi rejeitado por baixa nitidez no jogo
e molduras diferentes da referência. Os resultados técnicos abaixo são históricos;
não constituem aprovação visual. A investigação/correção parcial está em
[V05-CARD-03](card-assets-sharpness-v05-card03.md). As duas molduras e as seis
artes continuam protótipos, sem promoção ou aceite artístico.

Pedro anexou diretamente neste chat o conceito aprovado de 1280×720. Os pixels
foram visualizados: moldura dourada orgânica com folhas para Foli; curvas azuis,
dourado e orbe para Lonlon; entorno interno e **ambas** as placas indicam a
natureza do golpe. O nome inferior identifica o dono; a miniatura superior
representa o alvo atual. Esta imagem permitiu continuar a implementação sem
repetir nem contornar as transferências bloqueadas da Library.

A [spec integral](card-assets-spec.md) continua sendo o contrato. A arquitetura
[da primeira fatia](card-assets-implementation.md) permanece válida. Esta fatia
integra a apresentação em mão, inspeção e pilhas, preservando a versão 0.3.0,
regras, saves e pins atuais. Sem merge, push, deploy ou reativação de Actions.

## Entrega e ativação explícita

`ui/power-card-system@0.2.0` é um release **prototype**, independente do draft
0.1.0. A resolução usa as mesmas referências exatas e dependências do catálogo
existente, sem segundo pipeline, busca por latest ou imagens dentro dos saves.

```bash
source tools/environment.sh
godot --path . -- --card-preview
python tools/card_assets.py validate --release ui/power-card-system@0.2.0
# Recusa esperada enquanto faltarem arte e aprovação:
python tools/card_assets.py validate --release ui/power-card-system@0.2.0 --mode production
```

O argumento funciona somente na execução de desenvolvimento/editor. O export
normal mantém as cartas anteriores porque `runtime-lock.json` não foi alterado.
No export de fixtures do harness, `?test=1&card_preview=1&fixture=motion_dew`
abre a batalha real com a prévia; `?test=1&card_gallery=1` abre a galeria isolada.
A entrada/galeria de testes não pertence ao PCK de produção. Não existe setter
novo no bridge de produção. O gate de export exige cobertura/review completos
quando um novo binding for deliberadamente promovido.

## Composição e donos

| Componente | Seleção e responsabilidade |
|---|---|
| Moldura | Família + override explícito de forma. Foli/Folife compartilham a moldura moss declarada. |
| Ilustração | Espécie, forma e poder exatos. Evoluir preserva UID/instance_id e troca a arte. |
| Entorno, placa superior e placa inferior | Natureza do poder. Lonlon/Bosque mantém a moldura aquática e recebe placas verdes. |
| Nome inferior | Nome atual do dono, sem segunda miniatura do dono. UID permanece em tooltip/acessibilidade. |
| Alvo | Ocupante público atual da vaga sem consultar plano inimigo; cancelar remove; vaga vazia/área não inventam um indivíduo. |
| Valores | `Content.power_stats` e `Rules.power_effect` existentes, sem importar números do concept. |

`scripts/ui/card_target_view.gd` projeta somente dados públicos atuais.
`card_presentation.gd` copia os valores recebidos. `card_renderer.gd` apenas
desenha; não carrega arquivos. `power_card.gd` continua Button com o input e
movimento existentes, resolve assets antes de desenhar e mantém o caminho
legado. `card_preview.gd` reutiliza o mesmo componente em inspeção e pilhas.
A pilha agrupa por dono/poder sem revelar ordem de compra.

O renderer consome aspecto, região segura, região da arte e âncoras de
título/dono/custo/alvo do JSON. Ajusta a proporção dentro do Button existente,
sem esticar a moldura nem redefinir o layout/input da mão. Respeita os limites
de linhas com medidas da fonte nativa; `title_fits` consulta a mesma rotina
que desenha. O validator recusa regiões normalizadas que ultrapassam a carta.
O alvo carrega `portrait_source: form|enemy_art`: um Umbral adversário pode
usar a miniatura da própria forma sem confundir o alias de um inimigo de
encontro. Lado, UID e nome atuais permanecem explícitos; namespace desconhecido
falha com diagnóstico, sem emprestar outro retrato.

A seleção tem contorno e check. O retrato do alvo vem de um crop próprio;
o '+' só aparece quando o efeito real cura, e ataques usam seta. Textos são
nativos. O painel de inspeção mantém as descrições completas. O layout da mão,
quantidade de cartas, custos, slot semântico, escala de ações e animações não
foram redefinidos pelo mockup. O renderer se prepara para promoção futura;
esta entrega optativa não remove o caminho legado.

## Inventário real e proveniência

| Item | Presente | Aprovação final nesta entrega |
|---|---:|---:|
| Molduras de família | 2 candidatas (moss/dew) | 0; faltam ember/volt |
| Componentes de tipo | 12 (entorno + duas placas × quatro naturezas) | 0 |
| Ilustrações exigidas | 6 candidatas / 73 | 0; faltam 67 imagens |
| Miniaturas de formas | 14 referências reaproveitadas | 0 novas aprovações de enquadramento |
| Miniaturas de inimigos | 3 referências reaproveitadas | 0 novas aprovações de enquadramento |

As seis ilustrações são Foli `thorn_lash/root_wall`, Folife (form ID `verdalio`)
`thorn_lash/root_wall` e Lonlon `tidal_splash/dew_mend`. São imagens únicas:
não multiplicamos por cópia/UID nem fazemos a evolução herdar a imagem bebê.
Os módulos são `umbrals/card-art-moss`, `card-art-verdalio` e `card-art-dew`.
Duas molduras foram geradas a partir do conceito visível, com alpha real; as
placas/entornos são vetores originais convertidos para PNG pelo próprio Godot.
Fogo/Relâmpago estendem a paleta atual e precisam de review específico.

Os PNGs gerados foram copiados sem alterar seus bytes/metadados; manifests
registram hashes, arquivos originais e status. Originais permanecem em
`/workspace/generated_images` nesta sessão, sem caminho absoluto nos manifests.
As miniaturas reutilizam PNGs versionados atuais sem duplicar pixels. O rosto
de Foli recebeu crop/foco revisto nos pixels; as outras 16 identidades exigem
revisão visual em tamanho pequeno antes da promoção.

A demonstração Lonlon/Bosque continua isolada, não aprendível e fora das 73
combinações obrigatórias. Sua arte ausente é marcada `ARTE PENDENTE`. Imagens
candidatas mostram `ARTE EM REVISÃO`. Famílias sem moldura usam base neutra de
desenvolvimento, nunca uma moldura emprestada. Produção recusa esses estados.
O gate valida também referências declaradas ainda não selecionadas.

## Evidência, custo e limites de aceite

Foco preservado `artifacts/harness/card-preview-complete-pilot-20261108T063407239386Z-3b13b3/`:
arquitetura, contratos de UI, teclado/controle, gate de prévia, ambos os PCKs e
87 verificações Web passaram. Foram inspecionadas as capturas reais: a arte do
adulto difere da inicial; placas verdes de Lonlon/Bosque mantêm moldura azul;
os valores agora ficam sobre uma faixa legível dentro da arte. A captura
chamada `card-pile-populated` deste foco ainda mostra pilha vazia: o baralho
solo recicla imediatamente suas seis cartas. Esse resultado foi preservado;
o teste seguinte usa a fixture existente com vários donos e exige compra
não vazia antes de capturar, sem adulterar as regras.

O cenário `browser.cards` cobre cinco formatos (1280×720, 1440×900, 1920×1080,
1024×768 e 2560×1080), texto normal/ampliado, composição, alvo, inspeção e pilha.
São duas matrizes: galeria e mão real dentro do HUD. Na segunda, as opções
de texto são alternadas pelos controles reais de pausa/configurações; os
donos e cartas canônicos são comparados antes/depois. Um ataque selecionado
também registra a miniatura de um Umbral adversário.
Registra `card-runtime-measurements.json` com memória estática/texturas do
Godot Web, estimativa RGBA do cache e tempo de 100 buscas aquecidas. São
medidas deste ambiente Chromium/SwiftShader; não equivalem a FPS/GPU/RSS de
hardware físico. O cache limita referências a 32 texturas; referências vivas
nos componentes e cache interno do Godot também podem manter memória.

Foco final `artifacts/harness/card-preview-touch-cost-20261108T063801194508Z-f08389/`
passou: 99 verificações Web, toque injetado pelo Chromium, 438 verificações de
input com eventos Godot de teclado/controle, contratos de UI e gate de assets.
A compra com 12 cartas foi inspecionada: previews agrupados e nomes/contagens
permanecem no painel rolável, acima do botão Voltar. Na galeria, 14 texturas
no cache estimaram 53.370.720 bytes RGBA; o monitor de texturas do renderer
Web registrou 92.706.227–109.188.531 bytes (inclui outros recursos do engine).
Cem resoluções aquecidas custaram 9.400–17.700 microssegundos. O monitor de
memória estática Web retornou zero e é tratado como indisponível, não como
consumo zero. Estas medidas não cobrem todos os 73 pares nem hardware físico.

O fechamento integral atual e sua revisão serão registrados em
`artifacts/card-visual-layout-acceptance/`. Os resultados históricos da primeira fatia
não substituem essa execução: ela reprovou uma asserção de rolagem do grimório,
embora a repetição isolada sem alteração de código tenha passado 91/91.

A tentativa `artifacts/card-visual-acceptance/` foi interrompida após 112,848 s
para declarar a dependência herdada de `card-input` sobre `ui_flow_test.gd`.
Também reproduziu a falha do grimório. O diagnóstico registrou origem 210 e
retorno 269: `_restore_context` reaplicava `ensure_control_visible` depois de
restaurar o scroll salvo. Removida essa segunda rolagem; o foco continua
síncrono e o guard preserva um Tab posterior. O teste conserva a igualdade
exata e inclui ajuste manual da origem. Reintroduzir a linha antiga numa
mutação controlada fez o teste falhar; a fonte corrigida foi restaurada.
Arquitetura, harness e 91 verificações do grimório passaram no foco
`card-codex-exact-origin-fix-20261108T064714855511Z-7a9f31`. Tentativas negativas
e diagnóstico foram preservados; sem alteração de combate ou saves.

`artifacts/card-visual-acceptance-final/` foi interrompido após 1.833,199 s,
com fontes inalteradas e sem falha de asserção nessa tentativa: a revisão
identificou âncoras/aspecto ainda não consumidos pelo renderer piloto. Regras,
saves, os 859 checks do fluxo Web principal, layout, navegação, inventário e
combate haviam passado. Dez capturas de batalha normal eram RGB idênticas à
baseline. Essa tentativa não é aceite integral e foi preservada.

O primeiro foco do ajuste detectou erro de tipo Array/Array[String] na rotina
de texto; foi corrigido antes de aceitar o foco. `card-layout-contracts-fixed`
passou com 42 verificações de UI (incluindo os 18 títulos ampliados), 21 casos
Python de assets e os contratos de input/exports. Depois,
`card-proportional-hand-20261108T072730831389Z-a56c23` passou com 601 verificações
Web e 20 capturas de galeria/mão. O aviso de moldura ausente agora fica dentro
da área da imagem, com texto curto legível. Esses focos não substituem o gate
integral da última fonte, registrado no diretório acima.

Permanecem abertos: aprovação de fidelidade/identidade das seis candidatas e
das molduras/placas, as outras 67 ilustrações, duas molduras, review de todas
as miniaturas, dimensionamento/importação finais, memória e fluidez no
hardware-alvo, toque/controle físicos e aceite estético humano. A galeria é
uma ferramenta de revisão, não uma nova mão jogável. O concept completo com
mão em leque e recorte de HUD não foi transplantado como imagem de interface.
