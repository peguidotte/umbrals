# Referências conceituais de personagens e Umbrais

**V05-ART-REF-01 · importação de 05/11/2026.** Oito pranchas originais ficam
disponíveis no repositório para orientar a produção posterior. São conceitos
estáticos: aprovação da direção visual não aprova sprites, animações, escala em
cena, catálogo de espécies, nomes, naturezas ou poderes.

[Origem, escopo de aprovação e hashes por arquivo](catalog.json).

## Direções fornecidas como aprovadas

| Referência original | Escopo e limites |
|---|---|
| [Protagonista](direcoes/protagonista.png) | Aparência, roupa, expressões e acessórios. Nome e lore não são fixados por esta importação; o pequeno estudo pixelado não é um atlas animado. |
| [Brasa — final principal](direcoes/fogo-final-juba-completa.png) | Usar a variante **à direita, “Juba completa”**, com as três caudas. Este arquivo contém somente o comparativo do final; não contém uma prancha independente de Brasa inicial. |
| [Sendral](direcoes/sendral-cinzas-livres.png) | Direção visual de cinzas livres, inclusive cauda e detalhes junto ao corpo. Não fecha natureza nem regras. |
| [Lebre — linhagem](direcoes/lebre-linhagem.png) | Referência de formas inicial, intermediária e finais. A alternativa tem um refinamento próprio abaixo; legendas da imagem não criam arestas de evolução no jogo. |
| [Lebre — alternativa silenciosa](direcoes/lebre-alternativa-silenciosa.png) | Refinamento aprovado da alternativa, com folhagem cortante integrada nos quatro membros. Não implica ataque ou dano implementado. |
| [Água — companheira](direcoes/agua-companheira.png) | **Somente o painel inferior direito, “02 · ESFERA COMO COMPANHEIRO”**, é a direção aprovada nesta importação. A linha superior e “01 · ESFERA COMO NÚCLEO” ficam como contexto. A legenda “Linha aprovada” impressa no topo não amplia esse escopo. |
| [Família elétrica](direcoes/eletrica-rostos-pelos-azuis.png) | Referência de rostos, pelagem azul/violeta, espinhos e acentos elétricos. A prancha conserva rótulos de proposta: não infere seleção exclusiva entre finais A/B nem catálogo mecânico aprovado. |

## Proposta futura

[Mineral vivo — comparação original](propostas/mineral-futuro-comparativo.png):
somente **C · Mineral vivo** é guardado como proposta futura. **Não está aprovado
como inicial**. A · Vaga-lume e B · Nuvem viva são contexto da comparação, sem nova
aprovação. O título “Inicial elétrico” foi preservado nos pixels originais e não
altera essa classificação.

## Proveniência e integridade

- Os oito IDs fornecidos foram materializados pelo fluxo oficial da Library.
  O catálogo documental registra ID estável, ID de conteúdo, versão e nome
  original. Não contém URLs temporárias, tokens ou caminhos locais da máquina.
- Cada PNG foi copiado sem transformação. Tamanho recebido confere com o
  informado pela origem; SHA-256 de arquivo e dos pixels RGB, dimensões e modo
  estão registrados individualmente. Os arquivos de origem permanecem intactos.
- A leitura estrutural PNG, a decodificação integral e a inspeção visual das oito
  pranchas passaram. Nenhuma chave de metadados foi exposta por Pillow; nenhum
  metadado foi removido, pois todos os bytes foram preservados.
- Modelo, prompt e data original de geração não vieram na materialização.
  Não foram reconstruídos a partir de nomes ou do estilo. O vínculo da Library
  permite reconciliação futura com registros primários da geração.
- Textos como “proposta” e “em aberto” dentro das imagens são evidência histórica;
  o escopo recebido nesta tarefa consta na tabela e em cada registro do catálogo.

## Uso posterior

O marcador `.gdignore` mantém este acervo fora da importação do Godot, e os
presets existentes excluem `docs/*` da distribuição. Não são módulos de assets;
o catálogo aqui documenta fontes e não resolve arte em runtime.
`assets/runtime-lock.json`, o catálogo gerado de assets e os bindings não mudam.

Após revisão e integração deste PR, outros executores podem buscar a main e usar
os caminhos relativos acima, conferindo os hashes. Antes disso, as referências
existem somente nesta branch. Produção posterior deve seguir o
[pipeline de assets](../../assets/README.md): versões próprias, recorte/transparência,
pivôs, poses, animação, revisão em cena e promoção explícita. Nenhuma dessas
etapas está concluída por esta importação.
