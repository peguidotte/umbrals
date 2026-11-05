# V05-ART-01B — primeira onda da família Brasa

Registro histórico da primeira fatia (`2dce89c`). A continuação com poses novas,
KO e playback no jogo está em [V05-ART-01C](brasa-lifecycle-integration.md).

Base: `main@030ee7d9b2723ef6c75007cd5f9c17ec60da30ba`, confirmada por
`python tools/harness.py preflight --fetch` antes das edições. Worktree isolada,
sem incorporar a PR [#9](https://github.com/peguidotte/umbrals/pull/9), ainda
aberta durante a inspeção. Esta fatia remove parte do bloqueio de produção
da 0.5/0.6: uma forma real atravessa autoria versionada, importação Godot,
animação e revisão nativa. Não conclui o elenco nem o pipeline inteiro.

## Referências e decisões

A [família Brasa](references/creatures/brasa/README.md) tem como árvore de referência
inicial → intermediário comum → dois finais, fogo e cinzas.
`ember` e `ignivar` são IDs existentes preservados. Nomes falados Andarvor e
Sendral são preferências; novos identificadores e mecânicas não foram fixados.
O Sendral final usa cauda livre de cinzas controladas e partículas no corpo.
**Atualização posterior de Pedro:** o final do ramo principal de fogo voltou
à exploração, pois ainda parecia apenas crescimento e mais caudas. Não fixar
nem produzir sua arte final durante essa revisão. Sendral continua aprovado;
o trabalho no piloto de Brasa/base permanece autorizado e não é afetado.

Foram identificadas as duas imagens originais na Library, com nome, versão,
ID e tamanho. Ambas falharam ao transferir pelo fluxo oficial, antes da
instalação. **O repositório contém vínculos e registros, nenhum desses PNGs.**
Sem fontes alternativas, hashes inventados ou reconstruções da imagem aprovada.
Após liberar a transferência oficial, preservar seus bytes/metadados e conferir
os hashes antes de produzir as novas formas.

O [mineral vivo energizado, opção C](references/creatures/future-mineral/README.md)
foi registrado por pedido posterior como exploração futura, sem escolha de
inicial nem aprovação de produção. Sua transferência oficial também falhou;
há vínculo/proveniência, sem PNG local. Não se mistura ao fechamento de Brasa.

## Implementado nesta fatia

- Módulo `characters/brasa-pilot@0.1.0`, explicitamente `prototype`, com ciclo
  de blocking de um segundo/30 FPS e 31 amostras, incluindo endpoint repetido.
  Usa os vinte canais existentes e depende de `characters/battle-motion@1.0.0`.
- Autor determinístico em `tools/brasa_pilot/build.py`: conserva arte original,
  registra hashes/fontes e recusa reescrever uma versão publicada. O catálogo
  e o inventário de assets foram regenerados; bindings/pins permanecem iguais.
- Preview nativo em `tools/brasa_pilot/preview.gd`: atlas original de Brasa,
  fundo de batalha publicado, mesh/projeção de produção, idle e dano atuais,
  três casts atuais e blocking novo. Sem carregar main ou serviços de saves.
- Marcações de pivô de chão e sockets explícitos de boca, cauda e pata.
  O relatório nativo amostra suas projeções no mesh a cada frame; a origem
  sem deformação e os relógios de emissão/contato também são registrados.
- Verificação independente da PR #9: integridade, fontes exatas, loop fechado,
  canais finitos/escalas positivas, sockets explícitos sem fallback, pins
  preservados e correspondência entre capture e hashes de suas fontes.
  `--require-production-ready` falha com código 1 pelas lacunas declaradas.

Não houve nova pintura, geração de spritesheet ou substituição de arte. O piloto
importa e anima a arte atual em ferramenta nativa isolada. Não adiciona caminhada,
formas finais, evoluções, ataques ou mecânicas à experiência jogável. A PR #9
define um perfil de autoria com uma fonte de motion; não foi copiada nem mudada
para acomodar este piloto. Playback runtime e composição de fontes por forma
continuam decisões de integração posteriores.

## Revisão da captura

Evidência local, ignorada pelo Git:
`artifacts/brasa-pilot-final-20261104T231250Z/`. O log identifica Godot 4.6.3,
Compatibility/OpenGL e Mesa llvmpipe: renderização real em software, sem
alegar GPU física. Canvas 1280×720, sprite 184×180,53 unidades; 97 frames,
30 FPS, duração 3,23 s; 291 amostras de sockets. O vídeo contém seis vistas
da mesma forma, não seis criaturas ou opções de catálogo. Sem trilha sonora.

Observações na prancha nativa e nos frames do ciclo:

- Silhueta e cauda do Brasa existente permanecem legíveis contra o cenário.
  O atlas é filtrado em nearest e a região não inclui outra criatura.
- Boca fica no focinho; cauda acompanha o arco laranja superior; pata fica
  junto à mão dianteira no cast. Marcações provam projeção da origem no rig;
  este preview não comprova trajetória de VFX nem acerto de combate.
- O blocking fecha o loop e retorna à mesma pose, mas ainda parece balanço
  corporal. O apoio traseiro deforma e desliza ligeiramente; não há alternância
  convincente dos pés nem velocidade de translação. **Reprovado como caminhada
  de produção**, preservado como estudo para guiar a próxima autoria.
- Dano e casts são deformações da pintura existente, não novas poses desenhadas.
  Não existe derrota/KO neste módulo. Celebração não foi rebatizada como derrota.
- Não foi possível comparar com as pranchas aprovadas, pois os PNGs não chegaram.
  Esta revisão confirma compatibilidade com Brasa atual, não fidelidade a Sendral.

Uma primeira captura fica preservada em `artifacts/brasa-pilot-20261104T2310Z/`.
Um check detectou divergência entre hash do autor e manifesto durante regeneração;
a falha foi preservada e a nova captura registra os hashes dos arquivos usados.
A importação manual inicial também registrou erros de configuração do editor;
repetida com config/cache/user data isolados, terminou sem esses erros. O log
renderizado contém só o aviso de V-Sync indisponível no display virtual.

## Testes e limites

- Três testes de autoria: reprodução dos bytes sem alterar fontes/pins, rejeição
  de release publicado e rejeição de cauda ausente sem fallback para boca.
- Pipeline: 69 releases, 190 arquivos, integridade/imutabilidade aprovadas.
- Harness focado `brasa-pilot-focused-20261104T230947228042Z-743901`: assets,
  asset-unit, import, asset-catalog, battle-motion e architecture aprovados.
  Como foi seguido de ajustes no tooling/capture, é evidência desse run,
  não aceitação completa da fonte final.
- Relatório final do piloto e execução após congelamento são indicados na PR.
  Testes focados não comprovam diversão, hardware, áudio ou aceitação completa
  do jogo. Produto permanece 0.3.0. Sem merge ou publicação de jogo.

## Próxima onda e handoff para o integrador

1. Trazer as três referências pelo fluxo oficial. Separar fechamento criativo
   de readiness técnico e preservar proveniência/PNG originais.
2. Produzir caminhada com apoios alternados, velocidade e KO/retorno próprios
   de Brasa; revisar poses e sockets em vídeo. Só depois promover outra versão.
3. Definir o contrato runtime de locomoção/seleção de motion por forma, juntando
   os componentes desta fatia e o contrato da PR #9 após revisão do integrador.
   Só então alterar pins, facades ou registro compartilhado do harness.
4. Produzir intermediário/Sendral em ondas, usando a referência final de cinzas.
   O final principal de fogo aguarda nova exploração/aprovação; não produzir
   sua arte final agora. Criar IDs por autoria de conteúdo somente com decisão própria
   de compatibilidade; não renomear os atuais a partir de transcrição de voz.

O integrador deve registrar V05-ART-01B no roadmap quando revisar/integrar:
referências **vinculadas, transferência pendente**; piloto **nativo revisado,
blocking reprovado para produção**; próximas lacunas acima. O roadmap/registro
compartilhados não foram editados nesta worktree, conforme o handoff solicitado.
