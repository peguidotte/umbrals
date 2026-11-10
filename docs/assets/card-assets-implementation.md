# V05-CARD-01 — contrato e cobertura de apresentação

**Continuação após o anexo direto:** Pedro enviou os pixels aprovados neste
chat. A integração visual possível está implementada no piloto explícito
[V05-CARD-02](card-assets-visual-v05-card02.md). O bloqueio descrito abaixo é
histórico das transferências da Library; não impede mais o estudo visual.
O draft 0.1.0 e a evidência desta primeira fatia foram preservados.

Base: `f29752cac7d6525865091896a1466eb65a490c9c`, preflight com fetch em
08/11/2026, sem divergência/modificações locais. O checkout inicial `74df8de`
foi atualizado por fast-forward antes de editar. A [spec recebida](card-assets-spec.md)
foi lida integralmente. Esta fatia remove o bloqueio técnico de autoria
estruturada das cartas na v0.5; a versão do jogo permanece 0.3.0.

## Bloqueio e escopo efetivo

As referências `libfile_5c99f7cc1ff481919a251afd30d5d28d` e
`libfile_d3ebb3c8c5888191a652713b6cc5b870` foram resolvidas na Library, mas
ambas as transferências dos pixels falharam com `download failed`. Não houve
tentativa por outra rota, recorte, geração de substitutos ou inferência de
aparência a partir de OCR.

`ui/power-card-system@0.1.0` é **draft, somente metadados**. Todas as referências
artísticas estão nulas/pendentes. O layout normalizado é um contrato técnico
provisório, sem calibração visual. As referências estão marcadas `blocked` e
o layout não tem review, impedindo promoção. Nenhuma arte nova foi produzida.

Conforme a migração em fatias da spec, `power_card.gd` e `hand.gd` aguardam
o piloto revisado. O binding novo não foi acrescentado ao runtime-lock. O jogo
continua exibindo suas cartas atuais. Galeria, renderer das molduras/placas e
badge de alvo dentro da carta continuam pendentes.

Um integrador editou pipeline, generated files e registro do harness. Não houve
mudança em regras, Resources de gameplay, progressão, fingerprints ou saves;
nem merge, push, deploy ou reativação de GitHub Actions.

## Donos e matriz confirmada

| Dono | Responsabilidade |
|---|---|
| `tools/card_visual_snapshot.gd` | Exporta Resources/APIs reais, percorre arestas e restaura fixtures. |
| `assets/schemas/card-presentation-v1.schema.json` | Contrato próprio; módulo v1 publicado permanece intacto. |
| `ui/power-card-system@0.1.0` | Inventário editorial draft de combinações e miniaturas. |
| `tools/card_asset_pipeline.py` | Schema, referências exatas, cobertura, aprovação, pixels/alpha, contraste e gates. |
| `scripts/assets/card_visual_catalog.gd` | Resolução/cache sobre o catálogo existente, sem conteúdo/regras. |
| `scripts/ui/card_presentation.gd` | View model puro dos valores recebidos. |
| `tools/harness_lib/registry.py` | Suítes card-assets, card-asset-unit e card-visuals no fechamento. |

| Família | Formas | Combinações |
|---|---:|---:|
| ember | 2 | 8 |
| moss | 4 | 20 |
| volt | 4 | 29 |
| dew | 4 | 16 |
| Total | 14 | 73 |

O exportador usa poderes iniciais, `Content.can_learn` e fechamento transitivo
dos poderes retidos em cada aresta, sem regex de `.tres` nem multiplicação por
UID/cópias. São 42 combinações iniciais, 70 aprendíveis e três exclusivas de
retenção de Água em Zuldar: `dew_mend`, `rain_sweep`, `tidal_splash`.

Também visita checkpoints em `tests/fixtures/*.json`, restaura cada candidato
com `Expedition.restore` e inclui suas cartas canônicas. Checkpoint reconhecido
que deixa de restaurar faz o exportador falhar. 43 snapshots históricos
restaurados não acrescentaram combinações. Lonlon/`thorn_lash` está declarado
como demonstração não jogável, fora das 73, sem conceder aprendizado.

Inventário artístico: quatro molduras padrão, overrides opcionais, 73 artes,
12 componentes de estilo (três por natureza), 14 miniaturas de formas e três
identidades visuais de inimigos. O relatório atual registra **0 cobertas / 0
aprovadas / 73 exigidas**, com 120 pendências de uso. As 14 entradas de moldura
por forma podem usar quatro assets padrão por decisão explícita.

## Contratos preparados para integração

`CardVisualCatalog.from_binding()` retorna null enquanto não houver pin novo.
Desenvolvimento isolado usa `open_release("ui/power-card-system", "0.1.0", true)`.
`resolve_owner_visual(species_id, form_id, power_id, power_nature)` seleciona
arte exata, moldura padrão/override e três componentes do tipo do golpe. Cada
família enumera suas formas em `reuse_default_for_forms` ou `form_overrides`.
Não há herança automática da ilustração. IDs não são convertidos em slugs.

`resolve_target_visual(public_target)` recebe `{kind: "single", portrait_key,
enemy, uid, label}`. `none`, `empty` e `area` não inventam destinatário único.
Chave aliada é form ID; inimigos usam art binding público explícito
(`characters/owl`, `characters/spore`, `characters/stag`), evitando colisão
com form IDs de espécies. Só campos públicos permitidos entram no resultado.
O integrador deve atualizar a projeção na seleção, cancelamento ou troca de
ocupante do slot, sem passar plano privado/previsão oculta ao badge.

`CardPresentation.build(card, owner_view, power_stats, effect, owner_visual,
target_visual)` recebe nome/form ID explícitos e stats/efeitos existentes.
Preserva IDs, copia dados e fornece `ARTE PENDENTE` quando necessário. Não faz
I/O nem altera saves/RNG/cartas. O futuro renderer deve desenhar esse marcador.

Cache LRU: 32 texturas por referência exata, sem UID. `prewarm(keys)` só aquece
chaves explícitas visíveis/próximas. Nada é carregado em `_draw`. Abrir outro
release cria outra identidade/cache. Diagnóstico único por chave inclui
quantidade de texturas e estimativa RGBA; não mede RSS/GPU ou referências
externas. Falta perfilar o piloto real, pois não há ilustrações novas.
Desenvolvimento pode carregar textura prototype com marcador; produção a recusa.

## Autoria e gates

```bash
source tools/environment.sh
python tools/card_assets.py matrix --output card-demand.json
python tools/card_assets.py validate
python tools/card_assets.py validate --mode production
python tools/harness.py check --suite card-assets,card-asset-unit,card-visuals
python tools/assets.py validate --base-ref origin/main
```

Desenvolvimento passa informando cobertura zero. Produção deve retornar 1
enquanto pendente; a suíte prova esse retorno e o bloqueio de um pin sintético
incompleto. `--release id@version` valida um candidato exato sem substituir pin.
O relatório completo fica em `card-asset-report.json` na pasta da tarefa.

O pipeline genérico valida schema/integridade de cada presentation. Web/Linux/
Windows executam gate estrito quando há binding novo. Sem binding, o build
atual segue explicitamente legado. Packed-catalog compara JSON e dimensões das
texturas referenciadas entre fonte/PCK em diretório vazio, mantendo exclusão
das fixtures.

Usar os módulos sugeridos na spec, referências `{id, version, role}` e
dependências exatas. Os checks novos de pixels aceitam rasters decodificáveis
por Pillow, incluindo PNG/WebP; reutilizar SVG requer validar/estender esse
caminho antes da promoção. Alpha, integridade, crop/foco, contraste 4,5:1,
reutilização com motivo/review e pendências sincronizadas são obrigatórios.

Promoção exige nova versão imutável, pixels inspecionados, layout revisto,
escopo catalog, pendências vazias e todos os assets/status/reviews aprovados.
Acrescentar textura de seleção realmente usada e piná-la; presentation continua
role data acessada via bound_file, sem binding de JSON. Regenerar catálogo/
bindings. Piloto parcial fica isolado em desenvolvimento; esta fatia só permite
ativação de produção com cobertura completa.

## Evidência e retomada

Baseline: `artifacts/harness/card-assets-before-20261108T002303795397Z-019544/`.
Layout passou nos cinco formatos com texto ampliado. Capturas de 720p, 4:3 e
ultrawide foram inspecionadas: são as cartas atuais de ícones genéricos; não
comprovam reprodução do concept.

`card-assets-contracts-20261108T003352965854Z-315149` preserva duas falhas reais:
redução do limite LRU não expurgava hits e web→card-assets ampliava indevidamente
a seleção após mudança de fixture. Correções expurgam hits e mantêm o gate
no exportador sem essa dependência. O foco seguinte
`card-assets-verified-20261108T003433104979Z-3b3579` passou em resolvedor,
harness e packed-catalog. O último foco
`card-assets-final-focused-20261108T003513772257Z-c1e49f` passou em resolvedor,
cobertura e unidades; assets/imutabilidade também passaram (97 releases/347 files).

O primeiro fechamento `artifacts/card-assets-architecture/` foi interrompido
deliberadamente após o headless e os dois packed-catalogs passarem: a revisão
identificou referências declaradas mas ainda não selecionadas (default/override).
Dois casos negativos reproduziram a lacuna e estão preservados em
`artifacts/card-assets-unused-reference-negative/`. O gate agora verifica todos
os assets declarados e rejeita arte não aprovada mesmo quando não selecionada.
Export com pin novo também executa a validação genérica de integridade/ciclos/pins.

O fechamento final está em `artifacts/card-assets-architecture-acceptance/`
(2.626,482 segundos, fontes inalteradas durante a execução). Passaram 20 casos
Python novos, 25 verificações Godot do resolvedor, 14.321 de regras, 559 de
saves, assets/imutabilidade, ambos os packed-catalogs e os dez cenários Web.
As cinco capturas de batalha têm pixels RGB idênticos à baseline. A comparação
de 139 arquivos de contratos, cartas atuais e pins também não encontrou mudanças.

**O fechamento integral reprovou** em `codex-nav`: uma das 91 verificações
(restaurar a posição exata de rolagem ao voltar). A repetição isolada, sem
alterar fontes, passou nas 91; evidência em
`artifacts/harness/card-codex-investigation-20261108T004808436857Z-dd9976/`.
Isso indica intermitência, sem apagar a falha ou constituir aceitação integral.
O primeiro diretório `card-assets-architecture-final` preserva outra tentativa
incompleta que perdeu a sessão de saída; o relatório de aceitação acima é a
execução completa, com logs preservados em arquivo.

As capturas reais foram inspecionadas diretamente nos cinco formatos, incluindo
texto ampliado, e nos modais de alvo/plano. A página HTML de review foi gerada,
mas sua abertura por file:// no Chromium retornou ERR_BLOCKED_BY_ADMINISTRATOR;
essa navegação não foi repetida por outra rota. Headless e igualdade de pixels
do renderer legado não aprovam o conceito novo. Não há prova de controle físico,
toque do novo renderer, memória/GPU do catálogo final ou Windows em execução.
Esta atualização documental foi registrada depois do fechamento; código,
schemas e assets da execução permanecem inalterados.

Próxima fatia: acesso autorizado aos pixels; piloto de uma família com duas
formas/dois poderes e fixture de técnica compartilhada; revisão em tela; só
então integrar view model em power_card, mão, inspeção e pilhas, com alvo
público e contratos de input/modal/acessibilidade. Continuam abertos arte
completa, galeria, renderer, leitura em escala e memória real.
