# V04-UX-05B — menu de início escolhido

## Plano antes da implementação

O usuário escolheu a terceira revisão do menu com botões compactos, ícones
sombreados e logo UMBRAL sem subtítulo/emblema. A própria imagem original
selecionada é preservada em `assets/ui/title-menu/versions/1.0.0/texture.png`.
Ela fixa composição, tipografia, cores, retratos e ícones; não reinterpretar
esses elementos com controles genéricos.

Fatia: substituir somente a tela inicial, com quatro botões reais e navegáveis:
Jogar, Grimório, Opções, Como jogar. Jogar abre um submenu com Nova, Continuar
e Treino. O submenu preserva as confirmações e o save. Créditos continuam
acessíveis por Como jogar. Batalha, mapa, regras e versão 0.3.0 não mudam.

Um componente de apresentação possui a arte, regiões interativas e shader de
luz/energia nas cartas; o coordenador mantém a navegação. Movimento reduzido
cancela o efeito imediatamente. Toque nas cartas desperta luz sem iniciar jogo
ou alterar o save. As proporções da referência são preservadas, com margens
para formatos distintos; o texto ampliado expande os controles e sua arte.

Aceitação: comparar render real e referência no mesmo tamanho/estado, testar
quatro comandos, foco/volta, submenu/save, toque nas cartas, movimento reduzido
e formatos; gate completo `iterate.py --video`, revisão de capturas e vídeo.
Nenhuma métrica de pixels ou teste é tratada como aprovação humana da beleza.

Implementação e resultados verificados estão registrados no fechamento abaixo.

## Primeira rodada preservada

`artifacts/V04-UX-05B-title-20261031T225717110371Z` passou regras, oito
mutações, UI e export, mas falhou após 792 verificações do navegador: o
`settled()` esperava no máximo 15 segundos por uma fila longa de conjuração
na rota de Musgo. O snapshot da falha já mostra `busy=false`, ação 32 concluída,
e nenhum erro de Godot/JavaScript no console. A gravação por software foi
preservada. Ajustou-se apenas a espera desse assentamento para 60 segundos;
percursos, asserts, matriz, resultados e input real são mantidos.

A nova rodada completa não grava outro vídeo contínuo de toda a batalha. O
vídeo específico do menu (22 verificações aprovadas) e a gravação parcial
anterior cobrem o mesmo código de apresentação, que não foi alterado nesse
ajuste de sincronização. O resultado da primeira rodada permanece **failed**.

## Resultado verificado por etapas — 2026-11-01

A abertura está implementada e foi comparada com a terceira revisão escolhida
em 1672×941, densidade 1, estado inicial com movimento congelado: **zero pixels
diferentes**. A comparação conjunta e o vídeo real estão em
`test-results/V04-UX-05B-menu-final/index.html`. A mesma igualdade foi conferida
no adaptador local de hospedagem.

| Verificação | Resultado efetivo |
|---|---|
| Regras | 14413 verificações, sem falhas |
| Mutações | 8/8 detectadas |
| UI/fluxo/boot e catálogo | 673 verificações, incluindo 213 de catálogo |
| Expedição nativa/save/cena | 113 verificações |
| Batalha no navegador | 1855 verificações; quatro roteiros, três vitórias, casos elétricos e cinco formatos; 77 capturas |
| Expedição no navegador, repetição completa | 393 verificações; duas rotas e formatos de mapa, sem falhas |
| Menu dedicado | 22 verificações, teclado/toque emulado, efeito e movimento reduzido; console sem erros |

A validação final foi consolidada **por suítes no mesmo PCK**, e não como uma
invocação integral aprovada de `iterate.py`. Registro: `artifacts/V04-UX-05B-closure-20261101T005614768531Z/closure-report.json`.
O SHA-256 do pacote é `778d0ce6a32c5b12ef0710a5f4b8f9d89e6c1cf398d2e4d9e81daa8212b33875`. Os arquivos de código, testes, ferramentas,
assets e cena permanecem iguais ao manifesto da segunda rodada; esta
documentação de fechamento foi escrita depois. Produto permanece 0.3.0.

A segunda tentativa integral preservada também terminou **failed**: depois das
1.855 verificações de batalha aprovadas, o navegador de expedição excedeu 30 s
na consulta da geometria de `#canvas`, após 247 verificações. Não houve erro
de Godot/JavaScript registrado; o timeout sozinho não comprova remoção do canvas.
A captura externa de falha perdeu o contexto ao fechar Playwright. A repetição
instrumentada manteve todos os passos/asserts, acrescentando captura de HTML,
URL e eventos antes do fechamento; as duas rotas passaram. A causa do episódio
anterior não foi reproduzida nem apresentada como bug corrigido.

Implementação: `scripts/ui/title_menu.gd` apresenta o PNG original com quatro
Controls reais e nomes acessíveis; `title_magic.gdshader` acrescenta refração
suave, reflexos, sete faíscas e pulso ao clicar/tocar. Movimento reduzido remove
o shader imediatamente. Não há animação de poses independentes das cartas.
Jogar abre Nova/Continuar/Treino, adotado por delegação; cancelamentos preservam
progresso, RNG e foco. Grimório e demais submenus mantêm seu conteúdo anterior.
Batalha, mapa, formação e regras não foram redesenhados nesta fatia.

Telefone físico, controle físico, leitor de tela, GPU real e sessões humanas
continuam sem validação nesta rodada. Nas proporções diferentes de 16:9, a
composição fica integral e centralizada, com bosque existente nas margens.
O preenchimento dessas margens e o contorno funcional de foco podem ser
refinados em outra fatia, sem bloquear a fidelidade da abertura escolhida.

## Publicação efetivamente confirmada — 2026-11-01

A prévia privada existente foi atualizada, preservando público e origem do save:
https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site
O serviço confirmou status `succeeded`, deployment
`appgdep_6ae6b8348c6481919d6e69789d47c9a1`, versão
`appgver_c695f45f0ec48191bde7dfed95dedfa1`.
Fonte do Site: `bd5452fd689cede73d04ca3cc4fc52fa0314b873`, em repositório
separado. Não houve push no repositório do jogo, alteração de audiência ou
publicação no Steam. O pacote é o mesmo validado pelas suítes acima.

`/novidades.html` mostra capturas reais e um trecho do efeito. A publicação
foi confirmada pelo serviço; a execução gráfica foi validada localmente no
navegador, sem afirmar um teste remoto autenticado ou em telefone físico.
