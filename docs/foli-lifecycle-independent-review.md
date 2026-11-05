# Foli: revisão independente de poses, preview v3

Parecer do revisor `foli_lifecycle_review`: **GO técnico somente para a branch
draft**. Sem merge/main, aprovação estética ou declaração de família completa.
O relatório original, painéis, PNGs temporais e relógios ficam em
`artifacts/foli-lifecycle-independent-review/v3/` e
`artifacts/foli-native-lifecycle-preview-v3/` na entrega de evidências.

O revisor inspecionou a inicial aprovada, os doze recortes e seu original,
as duas orientações a 118 px e a 2,4×. Os pixels dos atlas continuaram iguais
entre as revisões. A única normalização foi translação vertical inteira para
alinhar os pés. O loop 7 → 0 aparece duas vezes na sequência real, com
alternância das patas e sem deriva acumulada do pivô. Os 2,4 s de caminhada
do preview demonstram três ciclos; o perfil selecionado mantém 0,8 s.

A primeira revisão recusou a mistura entre silhuetas incompatíveis: apareciam
duas cabeças e dois apoios. A política opcional `settle_mode: cut` eliminou
essa duplicação. Os cortes caminhada → idle e recuperação → idle mantêm o
chão e a escala, mas ainda apresentam salto de postura, especialmente na
recuperação ampliada. O default compartilhado continua `crossfade`.

O vídeo v3 contém 171 quadros em 8,76 s, com timestamps reais e sem
interpolação. O motor registrou 247 frames em 8,65 s, cerca de 28,55 fps com
limite de 30. A amostragem do framebuffer varia; um quadro apresenta uma
descontinuidade horizontal compatível com tearing, cuja causa não foi isolada.
O parecer permite examinar poses e cortes; não garante cadência uniforme.

O preview chama a apresentação diretamente, com HP 48/48. Por isso o GO
visual não comprova troca, dano, KO, item, save ou regras. Esses eventos têm
testes e captura separados descritos em [V05-ART-02G](foli-lifecycle-v05-art-02g.md).
O revisor não editou fonte, perfil ou pin.

Continuam para revisão humana o peso do passo, patas dianteiras, salto de
postura e se o KO sugere sono demais. Uma pose terminal mais próxima do idle
pode melhorar a transição; restaurar a sobreposição não resolve esse problema.
Verso, lâminas próprias, Folife, Foslash e Folivel ficam fora deste parecer.
