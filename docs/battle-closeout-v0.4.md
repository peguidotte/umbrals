# V04-BAT-04A / V04-BAT-04B — circulação das cartas e leitura da rodada

Fechamento técnico do MVP de batalha após o playtest no iPhone relatado
em 29/10/2026. Produto **0.3.0**; critérios humanos do marco 0.4 continuam próprios.

## Captura — D44 confirmada

Capturar abre a escolha de uma vaga livre ou Reserva. A primeira vaga livre é
sugerida, mas só a confirmação captura. Voltar preserva indivíduo, passiva,
ofertas e RNG. Vagas ocupadas ficam indisponíveis; com três ativos, o destino
disponível é Reserva. As outras vagas não são preenchidas automaticamente.

Captura no campo entre encontros não custa ação. O próximo encontro mistura as
cartas de todos os ativos. Reserva mantém as cartas fora do ciclo; entrada
voluntária em combate custa uma ação. Time cheio exige escolher quem sai antes do destino; só a confirmação final
libera o indivíduo. A vaga dele é sugerida quando estava no campo. A API mantém
a herança da vaga por compatibilidade e rejeita um encontro irrecuperável.

## Reinserção sem blocos por dono

O defeito inseria as seis cartas novas como bloco numa compra vazia, adiando o
descarte do ativo anterior. Isso podia garantir uma mão só do recém-chegado.

Na compra esgotada, agora o descarte é reciclado normalmente antes da mistura.
As cartas que entram são intercaladas uniformemente na compra, preservando a
ordem relativa das cartas anteriores. Com compra restante, o descarte espera.
Cópias já descartadas de um reserva retornam ao descarte.

Planejar, cancelar e sincronizar repetidamente não compram nem duplicam cartas.
A entrada altera o ciclo após resolver; a mão chega na próxima compra normal.
Uma mão naturalmente só de um dono continua possível: não há cotas por dono,
compra grátis ou combo garantido.

## Leitura da batalha

- Faixa de comandos próprios com poder, dono, alvo/alcance, custo e velocidade.
  Abre o editor por toque; some durante efeitos para liberar as trajetórias.
  Não expõe fila inimiga nem promete desempates.
- Ações distinguem o plano das ações livres. PLANO permite inspecionar sem hover,
  editar alvos/remover e conjurar diretamente. Notas de Semeado avisam quando
  o gatilho chega antes da preparação.
- Execução identifica o efeito atual e quem age; a mão confirmada permanece.
- RESUMO explica a última rodada: HP efetivamente perdido, absorção de escudo,
  resistências, enfraquecimento, reações e motivo de cancelamento. Pode ser
  consultado também nas recompensas e no resultado final.
- Mochila com quantidade; o guia explica duas poções e uma reanimação já jogáveis.
  Guia/histórico têm rolagem e Voltar fixo. O botão tocado permanece na árvore
  até o fim do frame, corrigindo o erro de transição observado no celular.

## Reposição e continuidade

Se alguém cai na rodada que vence um encontro, a próxima luta oferece a
reposição gratuita antes de comprar ou comprometer a intenção inimiga, mesmo
com outro ativo ainda de pé. Continuar exige ao menos um ativo apto.

Recusar uma reposição é lembrado durante aquela luta; a mesma pergunta não
reaparece a cada rodada. Reanimar limpa essa recusa para permitir um novo
nocaute do mesmo indivíduo. Se o último ativo cair, a recuperação volta a ser
oferecida mesmo após uma recusa anterior. Cartas bloqueadas não são removidas.
Esses defaults de UX foram desenvolvidos por delegação para preservar D19/D37.

V04-BAT-04B fecha a reversibilidade dessa escolha: depois de recusar, ainda
é possível trazer uma reserva para a vaga incapacitada pelo custo voluntário
normal de uma ação. Só executa ao Conjurar, sem cura do antigo dono, compra
extra ou limpeza de cartas bloqueadas. A oferta gratuita na fronteira do
nocaute permanece. Default adotado por delegação, coerente com D33/D37.
Reanimar um reserva não o coloca automaticamente em campo.

## Revisão e fronteiras do módulo

| Área | Situação | Próxima evidência útil |
|---|---|---|
| Ações, velocidade, alvos e trocas | Implementados, com plano editável | Explicação do plano por novos jogadores |
| Captura, formação e ciclo | Destino explícito e reinserção corrigida | Escolha entre um, dois e três ativos |
| Nocaute, reposição e reanimação | Preservados, incluídos na revisão de ciclo | Custo percebido das cartas bloqueadas |
| Quatro naturezas e quatro reações | Jogáveis, com resistências explícitas e Interferência | Descoberta sem orientação verbal |
| Consumíveis e informação inimiga | Poção/reanimação; três modos sobre o mesmo plano | Visibilidade da mochila e compreensão da intenção parcial |
| Explicação do resultado | Histórico de fatos resolvidos | Distinguir potência, HP, defesa e escudo |
| Relíquias/artefatos, aprendizado, lojas e mapa | Aquisição nas fases 0.5/0.6; modificadores do motor já têm contrato | Construção da run após consolidar a batalha |
| Poses, acabamento e plataformas | Composição preservada; celular experimental | Mais hardware, controle físico e sessões humanas |

O feedback foi favorável ao núcleo e ao desafio percebido. Não aumentamos HP ou
dano inimigo arbitrariamente: corrigir o ciclo já muda as escolhas. Vitórias
heurísticas não provam dificuldade ou diversão final.

## Evidência e limites

O usuário confirmou abertura no Safari/iPhone, elogiou efeitos/ataques e apontou
clareza e os dois problemas de captura/compra. Sem semente, duração ou roteiro
fornecidos, esse relato ad hoc não equivale a cinco sessões formais.

Diagnóstico em `test-results/battle-closeout/`: regressão de reinserção falha
antes da correção; testes dirigidos e capturas atuais por toque. Primeiro
preflight: rodada, histórico, captura no campo e detalhes mobile sem erros do
Godot. A revisão encontrou sobreposição de histórico/intenção e truncamento;
ambos motivaram um refinamento preservando a composição.

**V04-BAT-04B aprovada localmente em 29/10/2026.** Evidência final:
`artifacts/V04-BAT-04B-late-replacement-20261029T053548186461Z/`.
Fontes congeladas: `ddd6da2c716bba5920550c4ffcaa66976d2c3464ad188d5fd97a9ef4433d68d6`.
Pacote Web: `6901852047f038ee398cd5503021ca444e4529363cafa9e9d17272de018ef146`.

- 14.413 verificações de regras, 443 de UI e 1.628 no navegador; zero falhas.
- Oito mutações detectadas, incluindo os dois bugs relatados, reposição parcial,
  recusa repetida e troca posterior indevidamente bloqueada.
- Quatro percursos: três vitórias completas e o percurso elétrico com
  Interferência/Condução; quatro reações, 3×3 real e 76 capturas.
- Cinco formatos: 1280×720, 1440×900, 1920×1080, 1024×768 e 2560×1080;
  texto ampliado, foco, modais e ausência de erros de script/navegador.
- 48 casos de ciclo, 1.651 transições, 113 efeitos de consumíveis, 24 entradas e
  35 capturas no campo, sem violar instâncias, slots ou HP.
- Exportações Web/Windows/Linux, ZIPs com CRC/SHA e inicialização/encerramento
  headless do executável Linux aprovados. Windows não foi executado.

`review-notes.json` registra a inspeção das telas reais de comandos, captura,
resumo, 3×3, texto ampliado e ultrawide. A leitura de movimento usa quadros do
vídeo original de 04A, com 1.438,52 s; 04B não altera os componentes de movimento,
efeitos, atores ou mão. Não há alegação de novo vídeo de 04B.

A faixa de comandos torna dono/alvo/custo/velocidade consultáveis; o resumo dá
uma explicação estável após os avisos temporários. Ainda há texto pequeno no
celular e rótulos de efeitos que podem cruzar legendas em movimento. Não são
atribuídas notas automáticas de beleza, diversão ou acessibilidade completa.

As tentativas anteriores continuam preservadas: uma encontrou um fixture de
captura inválida que contaminava o caso seguinte; outra encontrou reprodução
de cura clicando no lado inimigo. Fixtures e metadados de alvo foram corrigidos,
sem remover a comparação exata da mão ou relaxar os gates.
Emulação móvel não substitui iPhone físico; eventos sintéticos não são controle
físico. O marco 0.4 permanece condicionado aos playtests do [roadmap](roadmap.md).

## Próxima aceitação: cinco primeiras sessões

A implementação técnica desta fatia está pronta para jogar. O critério humano
continua sendo observar ao menos cinco pessoas novas, sem transformar testes
automáticos ou o relato positivo atual em sessões que não aconteceram.

Em cada sessão, começar pelo menu e deixar a pessoa concluir batalha → recompensa
sem explicação verbal prévia. Registrar semente, vínculo inicial, dispositivo,
duração, formação escolhida, vitórias/nocautes e pontos em que precisou de ajuda.
Observar se ela consegue:

1. Explicar dono da carta, HP individual, ações livres e custo de resortear.
2. Escolher um alvo, revisar PLANO e antecipar a ordem por velocidade.
3. Distinguir categoria de intenção de um ataque/valor/alvo garantido.
4. Interpretar escudo, resistência e uma reação usando os efeitos e RESUMO.
5. Escolher Campo/Reserva e entender troca, próxima compra e carta incapacitada.

Distribuir as cinco sessões entre os quatro vínculos, com espaço para uma
segunda tentativa após aprender. Comparar especialização solo, cooperação e
proteção sem forçar três ativos. Perguntar o motivo da captura/evolução e o
que parecia arriscado. Priorizar no próximo ajuste as confusões recorrentes;
só mudar números de dano/cura com contexto das decisões e do percurso.

O próximo conteúdo é uma expedição com rotas, loja, aprendizado e aquisição de
relíquias/artefatos. Essa camada usa o motor de batalha; não é requisito para
chamar esta entrega de fechamento técnico do MVP de batalha.

## Prévia privada e entrega

[Versão jogável](https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site)
e [novidades com capturas reais](https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site/novidades.html).
Publicação privada concluída em 29/10/2026, às 06:00 UTC; audiência preservada.
O commit da cópia Sites é `cdb80659330c815379959c09e804bf178eb0f863`.
`private-deployment.json` no artefato final registra versão/deploy, fonte e SHA
do pacote. O repositório principal não foi commitado ou enviado ao GitHub.

O pacote final passou por dois percursos de toque em Chromium 844×390:
captura no campo e captura na reserva → entrada por uma ação → próxima compra
com dois donos, doze instâncias únicas e resumo. Zero erros de Godot/JavaScript.
O carregador mantém o mesmo motor/decompressor validado em nove cenários,
incluindo gzip sem cabeçalho, fallback, integridade, offline/retry e falta de
WebGL. Esses nove cenários foram executados em 04A; abertura e requisição do
pacote final 04B foram repetidas nos dois percursos de toque.

A página de novidades usa quatro PNGs originais, com hashes/proveniência,
e foi conferida em 390×844 e 1440×1000, sem overflow horizontal ou links quebrados.
O arquivo de cartas é versionado por hash e mantém um alias para o carregador
anterior. O status terminal de publicação foi confirmado pelo Sites; a política
de rede desta nuvem impede conferir a página autenticada no host publicado.
A validação física da nova versão no iPhone fica para a próxima sessão.

## Incremento seguinte ao fechamento

[V05-RUN-01/SAVE-02](expedition-implementation-v0.5.md) integra expedição com
bifurcação e retomada exata, reutilizando o combate atual. O gate de cinco
primeiras sessões de 0.4 continua aberto. A próxima camada de conteúdo é
V05-ECON-03: mercador, edição e relíquias adquiríveis, orientando melhorias
futuras da batalha a partir do contexto da run.
