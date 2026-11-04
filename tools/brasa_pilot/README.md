# Piloto Brasa — V05-ART-01B

Este é o estudo histórico de malha 0.1.0, preservado como reprovado. Seu gate
de pins sem alterações se aplica ao commit `2dce89c`. A continuação integrada
usa [V05-ART-01C](../../docs/brasa-lifecycle-integration.md), poses originais e
um novo pin explícito; não executar o gate antigo como validação da continuação.

Uma forma existente, um módulo novo de protótipo e uma captura **nativa Godot**.
Usa os skills locais [Umbral](../../.agents/skills/umbral/SKILL.md),
[Create Game Assets](../../.agents/skills/create-game-assets/SKILL.md) e
[Godot Animation](../../.agents/skills/godot-animation/SKILL.md).
Leia o [escopo/evidência](../../docs/brasa-pilot-v05-art-01b.md).

```bash
python tools/brasa_pilot/build.py
python tools/assets.py build
python tools/assets.py validate --base-ref origin/main
python tools/brasa_pilot/verify.py

# Em um display gráfico, com user data/config/cache isolados:
godot --path . --audio-driver Dummy --script res://tools/brasa_pilot/preview.gd \
  -- --output=<diretório-absoluto-em-artifacts>
python tools/brasa_pilot/verify.py --native-dir <diretório-em-artifacts>

# Retorna 1 enquanto houver lacunas; nunca converter isso em passe:
python tools/brasa_pilot/verify.py --require-production-ready
```

O renderer amostra 97 frames a 30 FPS: idle e dano publicados, três casts publicados
e um ciclo de blocking novo de um segundo. Amostra por tempo explícito; o tempo
real necessário para renderizar não muda a cadência do vídeo. São seis vistas do
mesmo `ember`, sem nova forma/species. Boca, cauda e pata têm marcações turquesa;
o ponto amarelo e a linha horizontal mostram o pivô de chão. O JSON registra
as projeções em cada frame. Escala da criatura: 184 × 180,53 unidades
em canvas 1280×720. O atlas original passa pelo importador Godot e pelo mesh
de produção; não é uma animação HTML usada como prova de importação.

`pilot_rig.gd` só troca a amostragem do blocking, reutilizando `project()`, pele,
UVs e topologia do rig de produção. As demais vistas usam o rig sem alteração.
O novo JSON usa os vinte canais normalizados existentes. A caminhada **não**
tem apoio alternado dos pés, IK ou velocidade de translação aprovados. Idle,
dano e casts existentes não são poses novas desenhadas. Não existe derrota/KO
nesse módulo; celebração nunca é usada como derrota.

Os ferramentas/cenas ficam em `tools/`, já excluído dos exports. O módulo
`characters/brasa-pilot@0.1.0` é `prototype` e só pode ser carregado explicitamente
pelo piloto; `runtime-lock.json` e os bindings de produção não são alterados.
A PR #9 foi inspecionada como proposta de autoria; este piloto não a importa,
não depende de seu merge e não muda seu contrato/arquivos. Integrar o playback
de locomoção no runtime e registrar a suíte no harness cabe ao integrador,
após revisão. O validador acima produz evidência focada, sem se declarar
aceitação completa do jogo ou aprovação visual.

`build.py` recusa sobrescrever uma versão presente em `origin/main`. Reexecutá-lo
antes da publicação reproduz os mesmos bytes. A proveniência fixa hashes dos
sources publicados e do autor; o validador rejeita fontes alteradas, loop vazio,
coordenadas/projeções inválidas e mudanças em pins/bindings.
