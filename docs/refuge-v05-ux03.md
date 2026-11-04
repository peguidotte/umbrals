# V05-UX-03 — refúgio lateral

A direção aprovada é uma sala lateral explorável, na linguagem visual do menu.
Esta fatia substitui a entrada direta na preparação por uma faixa de caminhada,
com leitura à esquerda, área de repouso e bancada ao longo do percurso e saída
física à direita. Não estabelece se o lugar existe dentro de uma carta ou Umbral.

## Arte e composição

Cenário e ator são originais separados, gerados com OpenAI Image Gen a partir de
referências do próprio projeto. O cenário não contém pessoas ou criaturas
embutidas. A roupa contemporânea não fixa nome, história ou identidade narrativa.
Os PNGs originais e seus metadados são preservados; regiões e pivôs do atlas são
dados de apresentação. A caminhada usa seis poses selecionadas e repouso próprio,
com orientação espelhada; não é um ciclo preexistente dos Umbrais.

Módulos: world/refuge-lateral@1.0.0 e characters/refuge-traveler@1.0.0, fixados no
runtime-lock. Fontes e licença Cormorant existentes são reutilizadas. O fundo é
ilustrado, enquanto o ator tem contorno e sombreamento rasterizado compatíveis com
a família de criaturas. Não se declara uma grade de pixel art uniforme.

A referência conceitual aprovada na Library não pôde ser materializada: o helper
retornou download failed. A direção textual e os pixels dos assets originais da
main orientaram a criação. Portanto, não se alega comparação pixel a pixel com
esse conceito. Composição e escala foram iteradas sobre capturas reais do Godot.

## Interação e fronteiras

- A/D, setas, direcional e analógico movem o personagem. E/Enter/A consultam a
  estação próxima; Esc/B retorna ao título. Mouse/toque têm controles de segurar
  para caminhar e consulta por proximidade, sem teleporte para a partida.
- Cruzar a saída abre a preparação existente. Cancelar mantém posição e exige
  sair/reentrar na zona antes de abrir de novo. Não inicia nem substitui uma run.
- Grimório usa descobertas reais. A bancada informa melhorias indisponíveis.
  NPCs, carinho, afinidade, compras e visitantes persistentes não estão implementados.
- A faixa frontal é livre; móveis decorativos ficam atrás. Limites laterais
  bloqueiam movimento. Posição e poses não entram em checkpoints.
- Painéis suspendem movimento e restauram foco. Input mantido exige neutralização;
  perder foco da aplicação limpa movimento por ponteiro. Movimento reduzido
  preserva deslocamento e usa repouso estático no lugar da sequência cosmética.

RefugeSpace possui a geometria transitória; RefugeCanvas desenha os assets;
RefugeRoom emite intenções; ScreenHost controla raízes/painéis. Não há alterações
em regras, RNG, HP, schema de save, catálogo de criaturas ou documentos de lore.

## Evidências e limites

As rodadas locais lateral-input, lateral-regressions, lateral-first-visual,
lateral-composition-review, lateral-composition-native, lateral-final-layout e
lateral-pointer-regressions e lateral-pointer-review passaram. A última inclui
segurar mouse e eventos reais de toque no navegador para consultar o grimório e
atravessar a saída, sem usar teclado no percurso de toque. Incluem 23 checks nativos da sala, testes
anteriores de navegação/expedição, caminhada Web real e cinco resoluções.
Os relatórios ficam em artifacts/harness/ com identificadores imutáveis.
Capturas e quadros do vídeo foram inspecionados; revisão independente avaliou
integração e coerência visual. Eventos de controle são sintéticos, sem certificação
de hardware físico. A aceitação integral do HEAD e a CI são gates separados.

A execução push antiga do PR #6 falhou apenas no assert final de erros Godot;
a execução PR no mesmo HEAD passou. O log antigo não contém a mensagem do motor
e o host do artefato foi bloqueado. Não se contornou esse bloqueio nem se declara
uma causa não observada. O harness agora imprime as mensagens exatas no log comum,
mantendo o assert, para permitir diagnóstico nas próximas execuções.

O PR #6 e sua branch ficam preservados como tentativa visual rejeitada. Esta
fatia parte de main 5caaf7b em feat/lateral-refuge. Versão do produto permanece
0.3.0. Próxima etapa de produto: avaliar a execução lateral e definir personagens,
funções de melhorias e encontros afetivos antes de persistir novos sistemas.
