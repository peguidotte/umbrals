# V04-ART-08A — coreografias aprovadas no combate

O usuário aprovou a revisão 5 e pediu integração no jogo e na main atual.
Base inicial: `f67f73e`; integração final sobre `ce1ba2a`, preservando o novo
lobby V05-UX-01. As quinze coreografias agora acompanham eventos
reais de combate, com preparação, emissão anatômica, contato, consequência e
recuperação. Oito formas têm perfis próprios: Brasa/Ignivar, Musgo/Verdálio,
Gota/Marevéu e Volt/Tempestral. As três alternativas de cada poder se alternam
por indivíduo e técnica; as formas adultas começam por gestos diferentes.

## Responsabilidades e assets

- `battle_motion.gd`: dados imutáveis exportados da prévia aprovada, sem estado
  de sessão. `creature_rig.gd`: uma malha nativa por criatura, deformação local,
  raiz, espelhamento e projeção dos mesmos sockets visíveis.
- `attack_events.gd`: agrupa os alvos de uma técnica sem juntar cópias repetidas
  de cartas nem atravessar outro ator/poder. Resolve ator por slot e UID.
- `battle_choreography.gd`: relógio audiovisual, alcance adaptado ao campo,
  salto limitado pela margem superior, reações e cancelamento.
- `battle_vfx.gd`: materiais ilustrados, fitas, fragmentos e impactos locais.
  `resolution_feedback.gd`: entrega snapshots e indicadores no contato.
- `audio.gd`: quinze WAVs originais no pool existente de quatro vozes SFX.
  Reprodução explícita por stream mantém pausa e mixagem no mesmo caminho
  nativo; a reprodução automática por samples ficou silenciosa na captura Web
  testada. O stream produziu sinal real, medido no áudio capturado do jogo.

Pin de produção: `attacks/battle-performances` aponta para
`attacks/woodland-elements@1.1.0`, com dependências exatas de
`characters/battle-motion@1.0.0` e `audio/battle-performances@1.0.0`.
O protótipo VFX 1.0.0 e os PNGs originais permanecem preservados. O exportador
reproduz tracks normalizados a 30 FPS; o runtime interpola sem usar RNG de jogo.
São animações por malha sobre sprites originais, não poses redesenhadas.
Inimigos ilustrados antigos recebem ritmo corporal compatível sem emprestar
articulações calibradas de outra anatomia.

## Contratos preservados

O modelo continua resolvendo a fila determinística uma vez. A apresentação
consome seus eventos e entrega snapshots na ordem original; HP visível muda
no contato, e efeitos de área usam um gesto com contatos escalonados em 45 ms.
Fila intercalada, UID, slots semânticos, cartas possuídas, cópias, resistências,
regras, saves e RNG não foram alterados. Botões, rótulos e áreas de clique ficam
fixos enquanto a malha se move.

Pausa congela relógio, corpos e voz ativa. Sair do combate cancela tudo.
Ativar movimento reduzido durante uma animação encerra o movimento, limpa o
feedback e entrega os snapshots restantes pelo caminho rápido existente.
Preferência de flashes controla apenas luz local; não há flash de tela inteira.
O impulso de câmera é limitado inclusive em ataques de área. Corpos
incapacitados não continuam respirando.

## Evidências e limites

Suíte nativa `battle-motion`: 38 verificações, incluindo HP no contato, área
versus cópias, três variantes em turnos reais, pausa, cancelamento,
acessibilidade e RNG preservado. Ela integra o grafo completo de aceitação.
As quinze fixtures (sete anteriores e oito novas de movimento) passam por
checkpoint/replay e verificação do PCK; nenhuma entrada de teste é exportada
para produção.

Validação focada de integração, UI, fixtures, exportação e arquitetura passou
em `artifacts/harness/integrated-stream-audio-20261104T134705800222Z-10539b/`.
Capturas adicionais usam controles reais no build Web e áudio do próprio jogo.
Falhas intermediárias foram preservadas, incluindo triangulação degenerada
de fitas e as primeiras gravações Web silenciosas, ambas corrigidas.

A aceitação completa passou com vídeo na base inicial em
`artifacts/harness/battle-motion-main-20261104T135855270594Z-cc5b31/`.
Depois da atualização da main, o grafo completo passou novamente, com fontes
congeladas e cobertura completa, em
`artifacts/harness/battle-main-lobby-20261104T144151943104Z-e38e27/`.
As duas rotas de expedição, os dez cenários Web e as cinco resoluções passaram
no conjunto atualizado. Os 394 arquivos de scripts/assets compartilhados,
exceto a view do lobby, mantêm os hashes da versão filmada; esta repetição
capturou novamente os estados sem refazer o vídeo do movimento inalterado.
As notas e o registro de continuidade ficam junto ao relatório final.

Captura Web com renderização por software e
validação digital de áudio não representam medição em hardware nem audição
física. Balanceamento e diversão continuam sujeitos a playtest humano.
