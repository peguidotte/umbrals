# V05-ART-01 — Pietro a partir da referência aprovada

O ator provisório da casa foi rejeitado por Pedro por ser caricato e destoar
do mundo. Esta fatia substitui apenas o binding visual do protagonista e seus
dados de poses, em branch sobre `feat/pietro-starting-house` no commit `a27c018`.
O PR deve permanecer draft até revisão independente; a casa continua sendo
responsabilidade do PR #11.

## Referência e direção

A transferência oficial da Library funcionou neste executor após a atualização
do ambiente. Foi usado `prepare_materialize` e o helper atual da skill Library,
sem download alternativo. A imagem foi decodificada e inspecionada antes da
geração: `libfile_7a1f2d2e78ac8191a4109773df9dce86`, versão 0, arquivo original
`exec-b7298ec7-edce-4c34-a9c7-02f7584b7de9.png`, RGB 1536×1024,
2.777.227 bytes, SHA-256
`341e3bacc0faff403b09c2698c7af0b0473842de36db264f49f9d2472ce39858`.
A identidade e versão foram verificadas nos xattrs locais. A cópia original fica
em `review/approved-concept.png`, excluída da importação pelo Godot.

O conceito orienta cabelo escuro ondulado, pele clara, rosto mais contido,
azul escuro, marfim e ocre. A roupa doméstica simplifica a roupa de viagem:
camisa/sobreposição azul, lenço ocre, calça escura e botas, sem mochila.
O atlas real dos Umbrais orientou textura e contornos; o cenário da casa foi
referência de paleta, sem ser misturado ao personagem.

## Contrato de integração

`characters/pietro-home@2.0.0` contém o PNG original transparente, intacto,
oito poses em grade 4×2 e regiões/pivôs explícitos. Repouso usa a pose 0;
caminhada usa seis poses a 9 FPS no consumidor existente. A pose 7 fica
reservada para avaliação, sem prometer animação de respiração não implementada.
Esquerda usa o espelhamento já existente. A nova versão major registra a
recalibração de escala/pivôs; a release 1.0.0 permanece imutável.

O PNG gerado mede 1774×887 RGBA, 797.521 bytes, SHA-256
`b682c7d9d6492062df4e0120b8cc20ee229ed081c18f1836c8c89b7493edb4bc`.
Não havia metadados embutidos na saída; os bytes originais são preservados.
Há alfa residual de valor 1 na periferia da imagem. As regiões são definidas
pela silhueta visível e margem; não houve reparo, recorte ou redimensionamento
do PNG. A altura visível varia menos de 3 unidades no mundo e os pivôs usam
a sola visível, em vez do fundo da célula. A sombra continua pertencendo ao motor.

Nenhum script da casa, geometria, câmera, regra, sessão, save, conteúdo mecânico
ou RNG foi alterado. O único pin alterado é `characters/pietro-home`; catálogo,
inventário e bindings são regenerados pela ferramenta existente. Na integração
com outra frente de assets, preservar a união dos módulos/pins e regenerar os
índices, sem substituir o arquivo compartilhado pela versão desta branch.

## Verificação e limites

`review/check_source.py` verifica a integridade das duas imagens, alfa, regiões,
margens, seis poses distintas, apoio dos pés e estabilidade de altura. Ele lê
pixels sem modificar as imagens e escreve relatório em `test-results/`.

O primeiro gate focado passou: 79 verificações de casa, catálogo Godot, assets
e arquitetura. A comparação visual usa builds reais com os dois pins e entradas
de navegador; capturas e MP4 ficam nos artefatos ignorados. O fechamento integral
e suas fontes congeladas são registrados no PR e no relatório de entrega;
este documento não antecipa resultado pendente.

O repouso é estático; caminhar usa seis poses desenhadas, sem rig esquelético.
Despertar ainda reutiliza a rotação da pose existente e a escada reutiliza a
caminhada lateral. Não há pose dedicada de deitar, acordar ou subir degraus.
A aprovação do conceito não equivale à aprovação estética deste sprite;
semelhança, fluidez e adequação visual continuam sujeitas à revisão de Pedro.
