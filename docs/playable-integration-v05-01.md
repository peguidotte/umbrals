# V05-INT-01 — candidata jogável de consolidação

Esta é uma candidata temporária, não uma declaração de entrega na main. A missão
é consolidar o trabalho existente e verificar o percurso casa → expedição →
combate → escolha → save/reload. Não amplia o escopo nem modifica CI/proteções.

## Composição revisada

Base GitHub `main@1523d0e7a34ef605bab140f9a979bc06a917f185`, confirmada pelo
preflight com fetch em 05/11/2026. A base já inclui Nascente contextual (#10),
ruleset 3, migrações e validação de assets (#9).

| Frente | Origem revisada | Estado da candidata e limites |
|---|---|---|
| Casa contínua | PR #11, `a27c0180abb6fb5322a13407e420ea102d47eb93` | Integrada localmente. Quatro regiões, dois pisos, câmera e escada física; ator e despertar provisórios. Referência visual aprovada não foi transferida. |
| Brasa | PR #12, `59033e3567bd2f40ec3d141f806d373d04d664a7` | Integrado localmente. Entrada, KO mantido e reanimação; os casts existentes permanecem. Sendral e o final com três caudas/juba completa não foram produzidos. |
| Elétrica | PR #13, `06806eb6ad923c4a6226717681aa8a1dbe77bc65` | Parcial: Nisca/Niscor em IDs existentes. Sem arte nova ou Auravel/Zuldar jogáveis. |
| Grama | PR #14, `8597f5ab9aead2172660a672fb4c138c953fbd36` | Parcial: Foli/Folife nos IDs existentes e nome nativo na galeria. Sem arte nova ou Foslash/Folivel jogáveis; grafia Foslash confirmada por Pedro. |
| Água | Nenhuma branch/PR de implementação publicada na consulta inicial | Bloqueada para esta composição até haver commits revisáveis. Não presume nomes/evoluções nem substitui a arte por imaginação. |

Esses estados descrevem a composição revisada. O relatório de fechamento e a
coordenação devem registrar qualquer nova origem incorporada e seus próprios
gates; o sucesso individual de um PR não valida a união.

## Donos e resolução

O integrador desta candidata é o único editor de inventários/pins/bindings,
roadmap e registro desta integração. A casa permanece dona de `house_*`,
`refuge_room`, `refuge_canvas` e testes de percurso; Brasa, de
`creature_lifecycle`, rig/ator/feedback e seus testes; elétrica, dos Resources
volt/judgment e verificações de nome; grama, dos Resources moss e da correção de
galeria. O integrador uniu os testes compartilhados do grimório. Novas frentes entregam diffs ao integrador
antes de tocar arquivos compartilhados. Main, Rules, sessão, registro do harness
e baseline arquitetural não receberam mudanças desta consolidação.

As entradas concorrentes de assets foram unidas e `tools/assets.py build`
regenerou índices/bindings sem diferença adicional: quatro bindings aditivos,
mais a revisão explícita de `world/refuge-lateral`. As releases da main foram
preservadas. O conflito de apêndice em `docs/roadmap.md` foi resolvido mantendo
os dois registros. IDs de indivíduos/formas/cartas e schemas de save permanecem.

## Evidências e aceitação

Antes do congelamento, o grupo focado passou em
`artifacts/harness/playable-integration-focused-20261105T012510888640Z-1acec3/`:
casa 79, battle-motion 59, catálogo 24, grimório/histórias, save, Nascente,
arquitetura e assets. A validação de módulos encontrou 75 releases e 206 arquivos,
sem falha; os três testes Python do piloto também passaram. Isso é evidência
focada, não aceitação integral. A união posterior de grama passou catálogo,
histórias/navegação do grimório, migração e save em
`artifacts/harness/playable-grass-union-20261105T013022740844Z-79f4ec/`.

A primeira rodada integral `playable-consolidation-20261105T012732053218Z-1e4a3a`
foi interrompida após 155 segundos para incorporar o PR #14 recém-publicado.
Seus gates nativos aprovados não representam aceitação integral. Relatórios e
capturas intermediárias permanecem intactos. O apêndice conflitante do roadmap
foi novamente unido, e os testes de histórias preservam elétrica e grama juntos.

Fechamento previsto: `tools/iterate.py --label playable-consolidation --video`,
com fontes congeladas, os dez cenários e cinco formatos de tela do registro
existente. O relatório imutável em `artifacts/harness/` identifica hash de fonte,
resultados realmente executados, falhas e capturas. Revisão visual e MP4 derivam
de renders/vídeo reais; nenhuma simulação será apresentada como avaliação humana.
O conjunto exato ainda precisa desse resultado e de revisão antes de integração
na main. Builds e evidências não são versionados. Não há publicação de release.

Próximo passo: concluir a aceitação, revisar imagens/movimento, reportar pronto,
parcial e bloqueado à coordenação. Uma origem posterior altera a composição e
exige nova validação proporcional antes do fechamento final.
