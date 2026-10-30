# V04-ART-06A — chão, fundo e profundidade

Estado: **implementado e validado localmente**. Esta fatia responde
ao feedback de que o fundo parecia ter baixa qualidade e alguns Umbrals, em
especial Orvalho, pareciam flutuar. Mantém o [formato aprovado](references/battle/00-aprovada/README.md)
e aprofunda a [primeira revisão](visual-review-v0.4.md), sem encerrar a família
visual nem o marco 0.4.

## Diagnóstico e escolha

O PNG anterior tinha detalhes miúdos/brilhos distribuídos pelo chão e era
enquadrado pela tela inteira, incluindo a parte escondida pelo HUD. O apoio
superior ficava próximo da margem do lago. Os sprites tinham proporções/áreas
transparentes diferentes, mas usavam a mesma sombra e o mesmo pivô genérico.

A recomendação aplicada é uma arena panorâmica com menos ruído, chão contínuo,
contatos de pés por arte e diferença discreta de escala. Uma câmera 3D ou
perspectiva muito forte mudaria a composição escolhida e consumiria o corredor
dos golpes; a profundidade aqui é de apresentação, sem frente/retaguarda.

## Implementação

- Novo fundo original `battle_clearing_depth.png`, 2172×724, com referência no
  cenário anterior e no atlas autoral. PNG copiado sem alterar pixels/metadados;
  prompt, hash e origem estão no manifesto e na proveniência. O anterior é preservado.
- Enquadramento usa a altura real do campo acima do HUD e filtragem nearest.
  Telas estreitas recortam laterais; o panorama ampliado cobre as largas, com
  extensão espelhada mínima além de sua largura. O topo recorta 4% de céu.
  Horizonte e proporção dos pixels ficam estáveis, sem
  esticar a imagem ou trazer a margem do lago sob os atores superiores. As faixas de escurecimento usadas no menu não cobrem a arena.
- Onze perfis de apoio nos atlas: centro dos pés, último pixel opaco e largura
  de contato. A respiração gira/escala em torno desse apoio, com sombra de contato
  e camadas suaves proporcionais ao corpo.
- Escala de retrato de 90%/100%/107% por posição superior/central/inferior; leve
  tom frio no alto. Rótulos e áreas de clique preservam tamanho e vagas estáveis.
- Intenção superior ganha margem do topo; o espaçamento entre atores preserva
  a separação entre status de um e intenção do seguinte.

## Conferência e limites

A prévia percorreu solo, dupla e trio por cliques/teclas reais, sem mutação da
ponte de teste. O 3×3 foi revisto em 1600×900, 1280×720, 1024×768 e 2560×1080.
Orvalho tem terra firme sob os pés nesses enquadramentos; Faísca não fica mais
sobre a vegetação alta do primeiro rascunho. Nome/HP/status e intenção do ator
seguinte não colidem. Os PNGs e snapshots ficam em `layout-previews/` da rodada.

A rodada `artifacts/battle-depth-20261020T034242826505Z` passou:

| Verificação local | Resultado |
|---|---|
| Regras | 9557 verificações; 100 percursos com heurística |
| UI, preferências e input | 49 verificações, sem falhas |
| Navegador real | 754 verificações; duas rotas até a vitória, captura/evolução e 3×3 |
| Matriz | Cinco formatos, opções e texto ampliado; 39 capturas no total |
| Assets | 47 originais/fontes/proveniências conferidos |
| Mutações | Duas regressões representativas detectadas |
| Export | Web, Linux e Windows; startup Linux headless sem erros |

Além das capturas com ociosidade congelada para comparação, foi percorrida uma
dupla com movimento normal ligado (`reduced_motion=false`, sem `visual=1`).
`idle-review/idle-grounding.webm` e seus quadros permitem conferir a respiração
com o apoio no mesmo chão. A sequência dos golpes do vídeo principal e o retorno
ao repouso também foram revistos em quadros, sem alegar audição em hardware.

`before-after.html` é uma comparação portátil das capturas reais, com PNGs
incorporados e controle por mouse/teclado. `review.html` reúne a rodada completa;
`review-notes.json` preserva observações sem reescrever `run.json`.

Hash das fontes capturadas: `bd9f4523514393a09dc47377b12598c37921a6dae4c68857c44e397964b1114e`.
Documentação e metadados de revisão foram atualizados depois da passagem;
nenhuma regra, UI, imagem ou dado de apoio dos atlas mudou após essa rodada.
A comparação de hashes confirma regras/catálogo/cartas iguais à base anterior.

As prévias anteriores foram preservadas: detectaram colisão de rótulos,
vegetação nos apoios e horizonte inadequado em telas largas antes da solução
final. O primeiro fundo limpo e os dois prompts permanecem registrados no
histórico de proveniência; os PNGs gerados não foram editados offline.

O sprite continua com uma pose estática; perspectiva desenhada, poses de ataque,
iluminação por golpe e todas as formas grandes em conjunto ainda exigem arte e
playtests próprios. O ganho de profundidade não deve sugerir cobertura, alcance
ou bônus inexistentes. Não há comprovação de compreensão/diversão por pessoas.
