# Naturezas, condições e reações — V04-BAT-03A

D41–D43 estão confirmadas pelo usuário: reações com resistências explícitas por
espécie, natureza principal e secundária em formas específicas, controle por
enfraquecimento/iniciativa. O usuário autorizou implementar a proposta. Esta
fatia está implementada no checkout; a validação completa passou localmente (evidências abaixo).
A versão de produto permanece **0.3.0**, com o marco 0.4 aberto.

Números, atribuições de catálogo e rotas abaixo são defaults reversíveis de
protótipo desenvolvidos por delegação, não balanceamento final nem aprovação
literal adicional. Referências: Pokémon para identidade/repertório; Slay the
Spire para estados legíveis; Divinity para reações; Balatro para combinações
reconhecíveis. Essas analogias não comprovam diversão.

## O que o jogador recebe

| Preparação + técnica ofensiva | Resultado executado |
|---|---|
| Encharcado + Raio | **Condução**: potência ×2; não consome Encharcado |
| Semeado + Bosque | **Brotação**: consome a semente, concede 6 de escudo à fonte original |
| Semeado + Água | **Floração**: consome a semente, cura 8 HP da fonte original; não reanima |
| Semeado + Fogo | **Incêndio**: consome a semente, acrescenta 4 Queima ao alvo sobrevivente |

Semeadura ocupa as duas cópias iniciais de Semente vital de Musgo. Custa uma
ação, tem potência base 6 e alvo individual. Planta por três rodadas, incluindo
a aplicação. Contra um alvo já Semeado, aproveita Brotação sem replantar nesse
mesmo golpe. O próximo poder distinto pode preparar novamente.

Interferência ocupa as duas cópias iniciais de Véu estático de Faísca: uma ação,
potência base 4, individual, aplica **Eletrificado 2**. Reduz em 25% a potência
do próximo ataque executado, em todos os alvos de uma área, consumindo uma vez
por técnica. Cura e defesa não consomem o estado nem sofrem redução. Não remove
ações e não muda a iniciativa já comprometida. Se o inimigo já tiver atacado,
o controle fica para uma técnica posterior, enquanto durar.

Semente vital e Véu estático permanecem no catálogo para aprendizado futuro;
lojas/aprendizado não estão nesta entrega. Cada indivíduo continua com **três
poderes × duas cópias**, sem cartas extras por evolução ou dupla natureza.

Os pools iniciais acompanham o repertório: Musgo deixa de sortear Vital após
a saída de Semente vital; Faísca deixa de sortear Resiliente após a saída de
Véu estático. Passivas conhecidas/indivíduos existentes continuam definidos no
catálogo; só novos sorteios são filtrados. Uma regressão compara cada candidato
com o mesmo indivíduo sem passiva, exigindo contribuição aos poderes iniciais
ou à Velocidade. Não conceder bônus implícitos a reações para justificar uma
passiva sem uso.

## Natureza, aprendizado e resistência são dados distintos

- Quatro naturezas: **Fogo, Água, Raio e Bosque**. Cada golpe declara sua própria
  natureza, independentemente do dono, e sua classe de aprendizado
  universal/por natureza/por linhagem. Uma técnica conhecida mantém sua natureza
  ao ser usada por outra espécie; Combustão continua sendo um trait explícito
  de ataques de Brasa, inclusive numa técnica aprendida de outra natureza.
- As quatro espécies têm uma principal. **Tempestral**, especificamente, tem
  Raio/Água; Faísca é Raio. As demais formas continuam com uma natureza.
  Trata-se de uma atribuição de protótipo à evolução de tempestade, não de
  uma regra para todas as evoluções. A compatibilidade de aprendizado está
  preparada no catálogo; não entrega poderes automaticamente.
- Resistências de dano são cadastradas separadamente. Nesta primeira seleção,
  Brasa resiste Fogo, Musgo Bosque, Faísca Raio e Orvalho Água, em **25%**.
  Tempestral conserva apenas a resistência explicitamente cadastrada a Raio;
  não recebe resistência a Água por sua segunda natureza.
- Técnicas não recebem um bônus universal por coincidir com a natureza do dono.
  Não há tabela universal de fraquezas ou imunidade de dano nesta fatia.
  Resistência não bloqueia condições, não altera duração e não reduz Queima.
- A inspeção e os tooltips mostram nomes/reduções públicos do corpo. Isso não
  revela a natureza ou condição do próximo golpe inimigo oculto/parcial. No modo
  completo, a inspeção da intenção pode mostrar os efeitos anunciados.

Ordem de dano: potência com ATQ/trait/passiva/Carga → Interferência → reação →
resistência → **um arredondamento para baixo** → Defesa → escudo → HP.
Exemplo: 20 ×2 ×0,75 −2 −5 = **23 HP**. Não arredondar Interferência antes da
reação. Escudo/cura/condições não recebem multiplicadores de dano por acidente.

## Contrato de condições

O catálogo determinístico fica em `scripts/battle/conditions.gd`. Contadores
numéricos preservam o formato anterior; `status_sources` guarda UID e lado.

| Condição | Reaplicação / consumo / duração |
|---|---|
| Queima | Soma intensidade; dano ao HP no fim da rodada ignora escudo, perde 1 |
| Encharcado | Renova para a maior duração; 2, ou 3 nas técnicas evoluídas; Raio não consome |
| Provocar | Renova duração; redireciona ataques individuais, sem alterar áreas |
| Carga | Soma bônus; não decai por tempo; próximo ataque consome uma vez, incluindo sua área |
| Semeado | Uma semente por alvo, duração 3; renovar não rouba sua fonte original; reação correspondente consome |
| Eletrificado | Duração 2; renova sem somar penalidades; próximo ataque consome |

Durações contam a rodada de aplicação. Só corpos aptos em campo avançam seus
contadores; reserva e incapacitação pausam, como os estados anteriores. Início
de encontro e reanimação limpam condições/fontes. Escudos zeram na próxima
rodada, inclusive quando uma Brotação beneficia alguém na reserva.

Semeado acompanha o indivíduo marcado e guarda o **aplicador original**, não a
vaga. Fonte viva na reserva pode receber cura/escudo; fonte incapacitada não é
curada nem substituída por outra. A reação ainda consome a semente. Se ela
conceder escudo a Musgo, Raízes Vivas pode curar uma vez por rodada, usando o
mesmo limite de outros poderes de proteção. Não propaga reações recursivamente.

A reação consulta o estado **anterior ao golpe**; aplicar uma condição não a
ativa gratuitamente nesse mesmo poder. Há no máximo uma reação principal por
alvo por técnica, com precedência declarada na lista em
`scripts/battle/reactions.gd`; áreas podem reagir uma vez em cada alvo. Não
existe sorteio de ativação nem ordem determinada pelos cliques.

Fogo e Encharcado continuam coexistindo. Água não extingue Queima e fogo não
cria Vapor. Inimigos usam o mesmo resolvedor de condições, resistências e
reações; técnicas específicas da rota aplicam Semeado/Interferência. Não são
traits novos concedidos indistintamente a todos os golpes inimigos.

## Disponibilidade pela run

Iniciar expedição abre quatro opções. Escolher começa com **um** Umbral, seis
cartas e três ações; cancelar não sorteia nem inicia uma run. Repetir a semente
conserva a espécie inicial. Capturas continuam uma escolha de recompensa,
entram na reserva e exigem entrada planejada ou ajuste entre encontros.

| Primeiro vínculo | Captura da primeira clareira | Captura da segunda |
|---|---|---|
| Brasa | Musgo | Orvalho |
| Musgo | Orvalho | Brasa |
| Faísca | Orvalho | Musgo |
| Orvalho | Faísca | Musgo |

São rotas curtas de demonstração para tornar os combos alcançáveis, sem equipe
pronta ou escolhas extras de recompensa. Não representam a distribuição final
de captura/biomas. Evoluir continua sendo alternativa à captura.

## Apresentação e limites

Cartas mostram natureza por nome e cor, com efeitos no tooltip/inspeção. O plano
explica condições e sequência possível sem calcular HP futuro ou expor a fila
inimiga. Atores mostram contadores compactos; a inspeção lista regras e fonte
original por nome e posição/reserva, com área rolável e Voltar fixo. Efeitos seguem a natureza **do golpe**,
inclusive para inimigos; nomes de reações aparecem na resolução. Avisos reservam espaço para toda a
trajetória, ficam dentro do canvas e empilham sem sobrepor dano, escudo ou cura,
inclusive com movimento reduzido; o pool continua limitado. HUD/câmera,
âncoras dos pés e panorama da revisão anterior são preservados.

Gelo/Pedra/Vento/Sombra, Resfriado/Geada, Rachado/Ruptura e Alastramento são
candidatos futuros, não conteúdo desta fatia. Mudanças comuns de Velocidade
valem na próxima fila. Não introduzir paralisia que pula turnos como regra de
Raio, preservando a direção D43 e runs solo.

## Aceitação

Verificar numericamente consumo/reaplicação, duração, fontes em KO/reserva,
limite de trait, áreas, ordem invertida, resistência, simetria inimiga e prévia
pura. A regressão histórica água/raio segue 38 versus 23 de dano no cenário de
Defesa/escudo zero e ATQ 10, com Circuito Vivo +4.

O harness deve jogar os quatro nomes de reação pela seleção inicial/capturas,
inspecionar efeitos/fontes e conferir os cinco formatos, incluindo texto
ampliado. Capturas/vídeo e revisão concreta são necessários; simulações de
vitória não medem diversão. Os resultados abaixo registram a execução, sem concluir os cinco playtests
humanos pendentes.


## Validação local de V04-BAT-03A

A execução completa passou: **12377 verificações de regras, 412 de UI e 1481 no navegador**, três mutações
representativas detectadas, quatro percursos de navegador (três vitórias
completas e um percurso elétrico até Condução), 3×3 real, cinco formatos de tela
e 74 capturas. Os quatro nomes de reação foram executados pelo fluxo
normal de seleção inicial/capturas, não por alteração da ponte de testes.

Evidências e vídeo: `artifacts/V04-BAT-03A-ready-check-20261028T232802583244Z`. Hash congelado das fontes:
`e6c7a197ecc96aa1e05f9c336fac4f795a83b716f5ce64de2f3b658483a0ea79`. A revisão concreta fica em `review-notes.json` nessa pasta;
é avaliação da IA sobre renders/quadros, não aprovação humana de diversão.

O teste de utilidade das passivas detectou Musgo/Vital e Faísca/Resiliente antes
da correção; o log está preservado. Os novos pools passaram. Os avisos foram
revisados para reservar sua trajetória e evitar sobreposição/clipping, inclusive
em movimento reduzido. Atlas, panorama e metadados dos pés mantêm os hashes da
revisão anterior. Tentativas interrompidas e seus motivos permanecem nas pastas
originais; não são apresentadas como aprovação completa.

Os números continuam de protótipo. Cinco sessões humanas, ritmo/balanceamento,
onboarding mais amplo, poses, Windows gráfico, controle físico e desempenho/áudio
em hardware real continuam pendentes. Gelo e demais naturezas candidatas,
lojas/aprendizado e aquisição de relíquias pertencem às próximas fatias.
Versão de produto **0.3.0**; marco 0.4 ainda aberto.
