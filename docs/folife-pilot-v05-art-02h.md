# V05-ART-02H — piloto visual da Folife

Fatia separada sobre o draft #20. A forma intermediária já existente
`verdalio` recebe o recorte da segunda criatura da v11, anatomia própria,
oito poses de caminhada e quatro de KO reversível. Espécie `moss`, UID,
passiva, poderes, cópias, aresta `moss_to_verdalio`, atributos, regras e
compatibilidade de save permanecem existentes. Produto continua 0.3.0;
sem merge ou declaração de linhagem pronta.

## Fonte e limites de aprovação

Referência aprovada, materializada oficialmente e inspecionada:
`docs/references/creatures/foli/lebre-linhagem-v11.png`, segunda forma somente.
O recorte original de ImageGen conserva RGBA 1254×1254 e caBX byte a byte.
Mantém orelha folhosa longa, broto, colar em camadas, cauda curta, chevron e
lâmina curta na pata. Cauda/patas um pouco maiores e expressão mais suave
continuam sujeitos à revisão humana.

A nova prancha 1448×1086 conserva seu original em `review/original.png`.
Os atlas 4×2 de caminhada e 4×1 de KO têm células 362×362. Alguns corpos
cruzavam a grade nominal; retângulos próprios e translações inteiras preservam
os pixels sem repintura, reamostragem ou mudança de alpha. O revisor independente
conferiu os doze recortes: zero perda de pixels com alpha >=128/240 e nenhuma
parte opaca de vizinho. Piso y=340, pivô explícito [150,340]. O chevron e pontas
do colar variam entre poses; oito poses distintas não certificam naturalidade.

O diagnóstico anterior de franja vermelha era incorreto: seu filtro contava
marrom legítimo. A composição RGBA real em fundos claro/escuro não mostrou
franja opaca; vermelho forte com alpha >=8 é zero. Restam resíduos de alpha 1,
por isso a escala usa bounds significativos. As tentativas antigas e o
diagnóstico corrigido permanecem em staging, sem apagar o histórico.

## Integração

`characters/folife-pilot@1.0.0` contém o retrato, anatomia e tracks próprios.
`characters/folife-lifecycle@1.0.0` fornece caminhada/KO e perfil do adaptador
compartilhado. Somente `umbrals/verdalio` e `characters/lifecycle-verdalio`
mudam nesta fatia; os pins da Foli e de todas as outras frentes permanecem.
O status técnico production permite seleção no draft, com production_ready=false;
não é aprovação estética nem publicação na main.

Apoio do retrato [500,1174], topo visível 55 e largura 850 foram medidos para
essa lebre intermediária. Os parâmetros mass/breath/tempo são de apresentação,
sem relação com atributos de batalha. Origem de antepata, colar e raízes usam
os pontos próprios da Folife. Um primeiro teste detectou a origem de raízes
no centro do chão, sem avançar para o adversário: o ponto foi corrigido no
perfil, mantendo o teste. Os VFX e os três casts continuam os de bosque
existentes; não são novas lâminas ou técnicas aprovadas.

O helper privado de lifecycle agora recebe a forma opcional; seu default
continua Foli. As duas expedições passam por snapshot validado, comandos de
troca e item, dano real e o mesmo UID. Nenhuma fixture é exportada ao produto.
O editor desta fatia possui os dois módulos, builder, testes de Folife,
parâmetro opcional do helper, dois pins e inventários gerados. Não edita
Rules, conteúdo mecânico, saves, registry ou baseline.

## Evidência

Revisão independente estática permitiu experimento em draft. O preview nativo
inspecionado usa quatro atores reais, duas orientações e 118 px/2,4×. Os
cortes walk→idle e revive→idle não duplicam o corpo; o chão se conserva. O
perfil de produção mantém caminhada de 0,8 s; o preview usa 2,4 s para
demonstrar três loops. MP4 real: 184 quadros/9,24 s, 1280×720, sem interpolação.
O chevron varia em movimento e os cortes ainda têm mudança de postura.

Uma captura separada da cena real executou 16 checks, zero falhas: UID 1,
HP 60 na entrada, 0 no KO mantido, 21 após item e retorno ao idle. Usa comandos
semânticos de produção, sem clique OS. XDG data/config/cache foram isolados
antes de iniciar Godot. MP4 H264: 220 quadros/10,96 s, sem áudio/interpolação;
timestamps e eventos originais preservados. Após os dois frames iniciais,
o motor registrou 219 frames/8,777 s (~24,95 fps), p95 de parede de 65 ms
e máximo de 253 ms.
Isso é uma medição desta execução, sem garantia em hardware alvo nem causa
provada para a diferença em relação à captura anterior de Foli (~8,4 fps).

O fechamento focado passou arquitetura, 73 releases/210 arquivos de assets,
456 checks do catálogo de assets, 123 de movimento, 86 de save e 22 da história
do grimório. Fontes antes/depois iguais durante a execução; os ajustes
posteriores são documentação e rótulos de revisão, sem mudar os inputs de
animação ou regras. A [revisão independente](folife-independent-review.md)
do ciclo real também deu GO técnico para draft. Identidades e relatórios
ficam no PR e na entrega de evidências. A primeira tentativa com a origem
incorreta está preservada como 123 checks/2 falhas. Não há aceitação integral
da combinação com a candidata por extrapolação destes testes.

## Próximas fatias

Verso desenhado, ataques de folhas-lâminas próprios, atuação final e escala
adulta no hardware alvo continuam abertos. Foslash e Folivel têm recortes
estáticos em staging separado, derivados respectivamente da terceira forma
da v11 e da alternativa v13. Não foram criados IDs, atributos, arestas ou
regras finais para elas nesta fatia. Lâminas nos quatro membros da Folivel
estão no conceito; variação de tamanho ainda não virou animação ou regra.
