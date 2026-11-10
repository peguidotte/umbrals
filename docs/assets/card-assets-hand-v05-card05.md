# V05-CARD-05 — leque interativo no combate

A mão da prévia Foli/Lonlon passa a usar as próprias cartas de combate em
leque. A seleção traz o mesmo botão para a região central da mão, ampliado,
sem criar outra carta no corredor da arena. Conjurar, alvos, custos, instâncias,
UIDs, regras, aprendizado, progressão e saves conservam seus donos existentes.

## Composição e entrada

- `hand.gd` conserva o índice canônico de cada carta e dispõe até seis cartas
  pintadas com aspecto 2:3, sobreposição e curvatura. A dimensão normal chega
  a 225 × 337,5 unidades lógicas; a carta em destaque cresce 1,4 vezes.
- A carta destacada sobe 145 unidades e usa o centro do leque para não ocupar
  os corpos/alvos laterais. Seleção e foco efetivo mudam o destaque. Hover
  conserva a edição de mira existente, sem deslocar outra carta sob o clique.
- A ordem dos irmãos acompanha a ordem visual, com desempate pelo índice
  original da mão. Reordenar nós não reordena `game.hand` nem o registro dos
  controles. O Godot separa Z visual dos sinais de mouse dos Controls:
  [documentação oficial](https://docs.godotengine.org/en/stable/classes/class_control.html).
- Cartas do leque selecionam no início do clique/toque, antes da animação.
  [ActionMode](https://docs.godotengine.org/en/stable/classes/class_basebutton.html)
  continua em release na mão modificada com rolagem. O limite de seis aqui é
  de apresentação; não foi criado um limite mecânico de cartas ou ações.
- Mãos maiores mantêm o caminho de rolagem anterior. Movimento reduzido usa
  as mesmas poses sem tween. Os modais continuam acima das cartas elevadas.
- `battle_hud.gd` deixa de instanciar `card_focus.gd`. A galeria estática não
  substitui mais a evidência da mão real.

Durante Conjurar, o destaque volta ao tamanho da mão para liberar o corredor
dos efeitos. As cartas comprometidas, seus alvos e a seleção permanecem
visíveis, com entrada bloqueada até o fim da sequência. A seleção seguinte
volta a destacar a própria carta normalmente.

O piloto conserva reservas, ações/Conjurar/Resortear e mochila/pilhas. A arena
mantém seu fundo completo. Os grupos ocupam uma faixa vertical menor, com
escala visual 0,8 e compensação 1,25 dos textos de campo. Slots 0/1/2 continuam
sendo superior/central/inferior, sem alteração de alcance. Avisos respeitam a
largura do corredor central e até duas linhas, inclusive com texto ampliado.

## Alvo e custo

A pintura continua específica da combinação forma/poder. A cena de Gota serena
mostra Foli, mas o destinatário confirmado vem do retrato circular e do texto
`Cura: <nome · UID>`. O aviso identifica `si próprio` quando o alvo é o dono.
Não há inferência do alvo a partir da pintura, nova cura ou troca de regras.

O custo é desenhado após o retrato/indicador de área e fica visível sobre sua
borda inferior. O nome atual do destinatário fica acima do retrato, separado
do sinal azul de cura. Nome do dono permanece na placa inferior, sem retrato
redundante. Placas e linha interna continuam seguindo a natureza do poder;
moldura continua sendo da família.

## Evidências e limites

`artifacts/card-fan-stable-focus/` passou 750 verificações Web, incluindo
alternância entre cartas sobrepostas, identidade dos seis nós, toque, edição
do alvo inferior e uma conjuração real. A matriz usa cinco formatos, normal e
ampliado. As etapas nativas posteriores de `card-fan-marker-final/` passaram
49 verificações de apresentação, 438 de entrada e o guard arquitetural.

A revisão visual detectou problemas que a contagem não detectou: custo
encoberto, aviso ampliado sobre HP e nome do alvo sobre o sinal de cura. Foram
corrigidos e capturados novamente. Há 12 telas em
`artifacts/card-fan-pilot-readable/`, com Foli/Lonlon em repouso/seleção,
720p/1080p e seleção ampliada. Quatro novas capturas de Lonlon em
`artifacts/card-fan-pilot-marker/` conferem o último ajuste do sinal de cura.
O delta posterior à matriz de 12 telas é apenas o deslocamento desse rótulo
para alvos individuais; as telas Foli/área e mãos sem seleção não o executam.
PNGs originais de cada captura e snapshots foram preservados sem redimensionar.

O vídeo revelou ainda a carta ampliada sobre os projéteis durante Conjurar.
`artifacts/card-fan-acceptance/` foi interrompido para corrigir esse ponto;
não é uma aceitação integral concluída. `artifacts/card-fan-cast-clear/`
passou 759 checks Web e os nativos. As capturas `card-casting-clear-lane-cold`
e `card-casting-clear-lane` mostram execução real com seis escalas 1, sem carta
ampliada e com entrada bloqueada. O corredor está livre antes do impacto.

O fechamento integral congelado atualizado fica em `artifacts/card-fan-final-acceptance/`.
Consultar seu `run.json`/`harness-run.json` e as notas locais de revisão para o
resultado efetivo; o caminho não antecipa aprovação. A baseline de `iterate`
é a implementação CARD-04, não o PNG original do conceito.

O anexo aprovado 1280 × 720 está visível na conversa, mas seus bytes originais
não foram localizados neste executor. O parent informou acesso em seu próprio
workspace. Não foi montada uma comparação conjunta com o original, repetida
uma transferência negada ou gerada outra aparência. `design-qa.md` registra
o bloqueio de fidelidade. As molduras e pinturas continuam candidatas: volumes
de raízes, curvas, ornamentos, poses e enquadramentos não são idênticos ao
anexo. A mão real é mais densa para preservar as quatro zonas do HUD; cartas
em repouso têm partes encobertas e a selecionada expõe a placa completa.

Nenhum arquivo de arte, catálogo, runtime-lock ou regra foi alterado nesta
fatia. Continuam seis pares jogáveis candidatos de 73, 67 ilustrações faltantes
e duas famílias sem moldura. Semeadura e Chuva lateral continuam explicitamente
pendentes. Não há promoção artística/produção ou ampliação de catálogo.
A prévia depende de `--card-preview` no editor ou `card_preview=1` no boot de
fixtures. Evidência visual é Chromium/DPR 1; densidade física Retina, hardware
real e aprovação humana permanecem sem certificação. Produto 0.3.0.

Não houve merge, push, deploy ou exportação de screenshots para Library/Space.
