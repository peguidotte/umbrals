# Lonlon → Lonaro: IDs aquáticos preservados

A linhagem aprovada é **Lonlon → Lonaro → Londraval (principal) / Lonelo
(alternativa)**. Esta primeira fatia integra os nomes e descrições das duas
formas já jogáveis. `dew` continua sendo a espécie e a forma inicial; `mareveu`
continua sendo o ID da segunda forma, agora exibida como Lonaro. A aresta
`dew_to_mareveu`, atributos, passivas, poderes, cópias e identidade dos saves
permanecem iguais. Os nomes de arquivo não são nomes de exibição.

Londraval e Lonelo ainda não têm formas/arestas jogáveis neste pacote. Veja
[escopo e pendências](../../../docs/aquatic-lineage-v04-09a.md).

O Resource da linhagem referencia os seguintes bindings de produção:

- `dew`: `umbrals/dew` → `assets/umbrals/dew/versions/1.0.0/manifest.json`, papel `portrait`.
- `mareveu`: `umbrals/mareveu` → `assets/umbrals/mareveu/versions/1.0.0/manifest.json`, papel `portrait`.

Estes releases são a arte aquática anterior, mantida como **fallback temporário**;
não representam a lontra aprovada. São retratos estáticos animados pelo rig de
apresentação já integrado, com repouso, preparação, conjuração, dano, defesa e
celebração. Não são novos sprites direcionais ou sequências redesenhadas.

A referência aprovada da lontra não pôde ser materializada pelo fluxo oficial
da Library nesta execução; seus pixels não foram inspecionados. Não houve troca
de pin, cópia de arte conceitual ou declaração de sprite final. Quando o conjunto
correto estiver disponível, registre corpo e esfera separadamente, ambos os
lados e estados no release versionado, fixe-o no runtime-lock e valide no jogo.

## Retomada V04-ART-09B

O impedimento de transferência acima é histórico. A referência foi lida em um
novo ambiente e gerou o piloto `characters/aquatic-family@1.0.0`. `BattleArt`
resolve os corpos de Lonlon/Lonaro pelo binding explícito; `CreatureRig` desenha
a esfera separadamente. Os bindings SVG acima continuam como fallback de
consumidores diretos. Finais, versos no runtime e animação desenhada seguem
pendentes. Veja [resultados e limites](../../../docs/aquatic-pilot-v04-09b.md).
