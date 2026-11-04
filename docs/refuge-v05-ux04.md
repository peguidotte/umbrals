# V05-UX-04 — proporção e sala sem instruções permanentes

Revisão solicitada por Pedro após avaliar o refúgio lateral: o ambiente parecia
desproporcional ao personagem e a barra de setas/consultar ocupava a sala.
O ator existente passa a ter escala de apresentação 34% maior, mantendo os pés
na mesma faixa de caminhada, com margens laterais para as poses ampliadas. A sala usa o quadro inteiro, sem cabeçalho, rodapé
ou instruções permanentes. A arte original e as versões dos assets são preservadas.

## Acesso e comportamento

Teclado e controle mantêm caminhada direta e consulta por proximidade. Mouse e
toque indicam um ponto no chão; o personagem percorre a distância à velocidade
normal. Livro e bancada recebem uma aproximação seguida da consulta real. A porta
recebe uma caminhada até a saída, sem abrir a preparação remotamente. Uma nova
escolha explícita da porta funciona após voltar; permanecer parado nela não
reabre o painel. Movimento direto, troca de foco, painéis e perda de foco da
aplicação cancelam a aproximação pendente.

Os objetos têm nomes de acessibilidade e recebem foco por Tab, com contorno apenas
durante o foco. Tooltips identificam o objeto sob o ponteiro. Um botão discreto
no canto retorna ao título; as opções continuam no menu. Instruções completas
ficam em Como jogar. O aviso de bancada indisponível aparece apenas após consulta
e expira. Não existe economia, afinidade, NPC ou cura ao caminhar nesta fatia.

## Direção de mundo e protagonista

Pedro passou a prever dois lugares distintos: a casa inicial e um abrigo portátil
que acompanha o protagonista. A preferência é situar esse abrigo dentro de um
Umbral da mãe. Isso é uma direção de produto com identidade, funcionamento e lore
a detalhar; a sala atual não confirma que já representa um desses lugares.
Não se implementa uma segunda sala superficial nem se altera o formato de save.
Os donos de geometria, apresentação, assets e fluxo já são separados; uma futura
seleção de lugar deve receber cenário e estações próprios antes de mudar a entrada.

O conceito do protagonista inspirado em Pedro é uma exploração visual separada.
O sprite desta revisão é o já existente. Pietro permanece nome provisório,
sem registro no código ou cânone. A transferência autorizada da imagem conceitual
pela Library falhou antes de criar um arquivo local; nenhuma imagem substituta
foi adicionada e a entrega dessa referência ao repositório permanece pendente.

## Evidência

quiet-room-input e quiet-room-regressions passaram; quiet-room-first-visual passou
com vídeo Web real e fluxos de continuar, confirmação de nova expedição e treino.
Capturas principais e de caminhada foram inspecionadas: ator maior em relação ao
sofá/bancada, pés e chão livres, ausência da barra. Revisão independente encontrou
o caso de reentrada explícita na porta, corrigido antes do congelamento final.
quiet-room-final-input passou 33 checks e arquitetura; quiet-room-final-visual
passou em Web com vídeo, incluindo reentrada na porta e caminhada por toque.
Essa comparação comprova a alteração visível; aprovação de proporções por Pedro,
teste de controle físico e acabamento final do protagonista permanecem separados.
Aceitação integral e CI do commit final são gates obrigatórios antes do merge.

As primeiras CI do commit 978e698 detectaram que a publicação periódica do estado
da sala podia parar antes da posição final exata na borda. O caso foi reproduzido
com falha nativa preservada (1/34), sem reduzir a asserção Web. A sala agora publica
chegada, início/fim de movimento e limites. quiet-room-final-publication passou
34 checks e arquitetura; quiet-room-boundary-web passou com captura da borda e
vídeo real. A aceitação local anterior foi interrompida e preservada para repetir
o conjunto completo com fontes congeladas após essa correção.
