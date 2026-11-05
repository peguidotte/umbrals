# V05-ART-01D — estudo de contato do Brasa, reprovado para integração

O objetivo visual ainda não foi atingido. A nova candidata
`characters/brasa-lifecycle@1.1.0` conserva `production_ready: false` e foi
**reprovada pela revisão independente**. Não integrar esta branch nem promovê-la
como animação pronta. A versão do produto permanece 0.3.0.

Base: PR #12, `11fbe7fe7ed6fdb7991aecc5529d7315bc190964`; preflight com fetch
confirmou main `1523d0e7a34ef605bab140f9a979bc06a917f185`, sem commits faltantes.
Branch separada: `feat/brasa-contact-recovery-v3`.

## Entrega preservada

- Oito desenhos de marcha novos, cinco de ligação ao idle e seis de levantar,
  incluindo endpoints. O levantar tem quatro desenhos próprios; não reproduz
  a queda ao contrário.
- Chegada e recuperação terminam nos pixels exatos do idle original. O início
  de recuperação coincide com o KO mantido. Há um só desenho opaco por vez;
  a dissolução entre duas silhuetas foi removida.
- Contatos explícitos em pixels das solas e deslocamento por desenho. Pausa,
  movimento reduzido, interrupção por impacto/conjuração e geometria de alvo
  continuam separados do relógio cosmético. A primeira pose recebe um tick
  inicial; um render lento não pula índices no consumidor.
- Original Image Gen preservado integralmente com hash. Recortes, escala
  nearest, translações e fontes de endpoints estão em `normalization.json`.
  Releases 0.1.0, 0.2.0 e 1.0.0 permanecem intactas.
- Sendral e final de fogo foram materializados pelo fluxo oficial da Library
  e seus pixels inspecionados. Ver
  [registro da transferência](references/creatures/brasa/materialized-20261105/materialization.json).
  O final aprovado é o quadrúpede de três caudas com juba completa, à direita
  de v9. Este estudo não implementa os finais nem muda IDs/conteúdo mecânico.

Uma segunda tentativa de geração de marcha foi descartada: apresentou ruído
semitransparente fora dos sprites e não resolveu a progressão das pernas.
Ela não foi adicionada aos assets do jogo.

## Parecer independente e medidas

A revisão de outro agente inspecionou todos os quadros decodificados, recortes
em seis vistas e as fontes. O contato de um pixel designado não comprovou
continuidade do corpo ou da sola inteira.

| Severidade | Evidência a 118 px | Consequência |
|---|---|---|
| P1 | Marcha 1→2: root salta 27,15 px; 5→6: 18,10 px; 3→4: recua 3,48 px | O corpo/focinho avança aos saltos apesar do contato designado estável |
| P1 | Levantar 0→1: topo da silhueta sobe 26,80 px; frente avança 11,49 px | A cauda infla antes da subida pelos braços |
| P1 | MP4 Web tem 40 quadros em 25,501 s; falta marcha 2, ligação 3 e levantar 3 | Oito índices no JSON não provam oito poses apresentadas no filme |
| P2 | Última ligação→idle altera a extremidade da cauda em 10,09 px | Falta aproximar o desenho anterior do endpoint exato |

Os defeitos de marcha foram reproduzidos nos dois lados e nas três alturas
106,2/118/126,26 px. A expansão inicial da cauda mede 24,12/26,80/28,68 px.
A revisão confirmou ausência de fantasma, espelhamento coerente e oito poses
visíveis no filme nativo de 1600×900. **Resultado: reprovar para integração.**

## Provas reais e seus limites

- `artifacts/brasa-native-1600-20261105/brasa-native-1600.mp4`:
  Godot/Mesa llvmpipe, 1600×900, 168 quadros a 30 FPS, 5,6 s. Filme nativo
  offline, não prova de desempenho em tempo real. Os overrides de janela foram
  ajustados somente num projeto diagnóstico isolado. A captura anterior em
  `brasa-contact-matrix-20261105/native/` é 1280×720 e não comprova as alturas
  físicas anunciadas nos rótulos.
- `artifacts/brasa-contact-matrix-20261105/web/brasa-contact-web.mp4`:
  canvas Web real a 1600×900, H.264 VFR. A cadência gravada tem intervalos de
  aproximadamente 0,310 a 1,349 s. O relatório de amostras mede estados
  processados e contatos designados; a inspeção dos pixels gravados tem
  precedência na cobertura de poses.
- `artifacts/brasa-contact-integrated-20261105/brasa-lifecycle.mp4`:
  1600×900, 62 quadros de vídeo, 22,710 s, H.264 + AAC do WebAudio real.
  Cliques reais confirmaram planejamento sem troca, entrada ao Conjurar,
  KO por dano, KO mantido e reanimação do mesmo UID por item possuído.
  Não comprova marcha fluida nem cobertura de todas as poses.
- Parecer completo, recortes e hashes preservados no pacote de revisão, junto
  dos JSONs e logs originais. Nenhum vídeo foi montado a partir de screenshots.

## Verificação

`verify_contact.py` passou os hashes, endpoints RGBA exatos, seis desenhos
distintos de recuperar e oito contatos situados em pixels opacos de pés.
Assets, asset-unit, arquitetura e fixtures passaram em execuções focadas.
A primeira execução de movimento passou 420 verificações; não é aprovação
visual nem aceitação completa.

O gate completo em `artifacts/brasa-contact-full-20261105/` foi preservado como
interrompido: falha de sincronização numa espera fixa da entrada, timeout de
240 s na tarefa de mutações e interrupção do percurso Web após essas falhas.
Regras, UI/estado, catálogo, domínio, saves/expedição, menu, assets, exports e
inventários empacotados passaram nessa tentativa; o grafo completo não passou.
A espera fixa foi substituída por espera limitada pelo avanço real de quadro,
mantendo as asserções de movimento e geometria. O primeiro reteste executou
420 verificações sem falhas funcionais, mas foi corretamente reprovado pelo
guard por recursos ainda em uso no encerramento; o diagnóstico permanece
preservado. Não declarar CI ou aceitação completa aprovados.

O diagnóstico posterior com `--verbose` executou as 420 verificações sem
erros de recursos no encerramento. Isso não explica nem apaga a falha anterior;
o encerramento tem resultado intermitente e precisa de investigação antes da
aceitação completa.

## Handoff ao integrador

Arquivos de apresentação afetados: `creature_lifecycle.gd`, `creature_rig.gd`
e teste de movimento. O pin novo escolhe 1.1.0 somente nesta branch de estudo;
inventários/binding foram gerados pelo pipeline. Main, fachada de regras,
conteúdo, RNG, saves, baseline e registro do harness não foram editados.
O integrador continua dono de roadmap/registro e de qualquer merge entre frentes.

Próxima fatia recomendada: trajetória do corpo antes de desenhar as pernas;
marcação inequívoca do pé próximo/distante; novos in-betweens que reduzam os
saltos e mantenham o contorno inteiro da sola; levantar com a mesma cauda baixa
do KO; ligação final próxima do idle. Medir focinho, peito e quadril junto dos
apoios. Depois repetir filme Web com cobertura conferida nos pixels decodificados
e todos os gates, mantendo esta tentativa imutável. Não aplicar IK raster às
pressas como substituto dessa revisão de anatomia.
