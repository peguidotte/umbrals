# V05-CNT-02A — Foslash jogável em draft

Foslash passa a ser uma evolução explícita de Folife: espécie `moss`, forma
`foslash`, aresta `verdalio_to_foslash`. Foli/Folife e a aresta anterior mantêm
seus IDs. Evoluir conserva UID, passiva, donos e instâncias das cartas.
Os atributos provisórios 72/14/6/12 e perfil 10/8/4/2/2 repetem o incremento
já existente entre Foli e Folife, melhorando cópias conforme D18. Isso não
constitui aprovação de balanceamento nem adiciona poderes ao baralho.

A forma usa a terceira lebre da v11, recorte/anatomia próprios, oito poses de
caminhada e quatro de KO reversível. Os originais gerados e a normalização
sem redesenho ficam nos módulos versionados. A última pose de KO recebeu
uma correção de geração para preservar a lâmina curta. O ator adulto tem
136 px lógicos de altura; alvo e chão preservam os contratos anteriores.

O poder existente `thorn_lash` recebe o nome cosmético “Lâminas de folhagem”
e ícone de folha. Seus IDs, custo, escopo, números e natureza continuam os
mesmos. Foli/Folife/Foslash usam carga na antepata e três apresentações de
lâminas com atlas próprio; contato, HP e RNG continuam no fluxo existente.
A lâmina pintada no corpo permanece durante o projétil. Quatro candidatas
adicionais de cast estão somente no staging, sem alegação de integração.

## Compatibilidade

A adição de opções altera a sequência de recompensas de novas runs, por isso
há uma decisão explícita de ruleset 4 e `catalog_revision` independente da
revisão da Nascente. Saves rules 2/3 e schema 1 conservam catálogo 0; runs
novas recebem catálogo 1. A migração só remove o sufixo de forma/aresta
explicitamente auditado para comparar manifestos históricos e continua
rejeitando identidades desconhecidas e formas forjadas. A identidade desta
fatia é `expedition-rules-4` /
`07942959b491e5c9466c7133b0a4b1809283f9aee7162d405af6ff31aa278442`.
Um replay real de 59 comandos anterior à adição permanece como fixture.

## Evidência e limites

- Saves: 180 checks; expedição/regras: 56. Arquitetura, recursos, import,
  catálogo e assets passaram nos alvos focados.
- Movimento: 234/0 em
  `artifacts/harness/foslash-mature-defense-fixture-20261105T062145480305Z-0fa8ac/`.
- `artifacts/foslash-native-ui-v3/`: 25/0, escolha da evolução por mouse X11,
  mesmo UID 1 no boss e variantes 3/4/5. 533 amostras reais e MP4 VFR.
  Revisão independente confirma os eventos; a cadência da cena completa
  neste executor não permite chamar a animação fluida.
- `artifacts/foslash-native-game-lifecycle-v2/`: 16/0, comandos reais sobre
  uma expedição privada validada, HP 72→0→26, UID 1, KO persistente e
  recuperação. Não é uma alegação de input de mouse para o lifecycle.
- O primeiro KO falhou (16/5): a defesa adulta absorveu o primeiro golpe.
  A fixture agora avança rodadas reais até um plano que cause KO, sem
  alterar catálogo, intenção ou dano. A tentativa está preservada.
- Preview nativo controla apenas apresentação para revisar poses/cortes;
  não serve como prova de regras. Há pop de postura entre atlas e retrato.

O verso de Foslash não foi produzido: o ImageGen recusou a operação antes
de criar arquivo (`moderation_blocked`, output/other, request
`2d6be8eb-41b3-4f56-97d4-9c954464867b`). Não houve retry ou rota alternativa.
O lado oposto continua sendo o frontal espelhado e está declarado como tal.
Folivel e versos das formas menores ficam em fatias posteriores.

A observabilidade de CI registra versões esperadas/observadas e o diff
antes de preservar o erro original `Mixed tool versions`. Não muda seleção
de browser, timeout ou gate. O desvio exato do #20 não foi preservado pelo
runner; Chromium é hipótese, não causa comprovada. O #21 passou todos os
sete grupos e Aggregate. Patch amplo de infraestrutura continua separado
e não aplicado. O fechamento completo com vídeo será executado sobre a
candidata congelada que incorporar as próximas fatias, sem atribuir a
esta árvore o verde de commits anteriores. Sem merge; produto 0.3.0.
