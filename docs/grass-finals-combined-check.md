# Combinação de verificação da linhagem de grama

Branch de suporte `integration/grass-finals-check-20261105`, sem atualização
ou merge da candidata #15/main. Combina a candidata #15 `f5bfc21`, preservada
pela integração anterior `2ff88c5`, com #23 `c7f9ec18` e #24 `2c5160f`, mais a correção de teste `a9dc51e`.
Preserva todos os commits de origem e o adaptador moderno compartilhado.

Resolução deliberada dos únicos conflitos: união de runtime-lock, mantendo
os quatro pins Foli/Folife 1.1.0, os dois finais e as folhas; incorpora o pin
global Brasa e os pins da casa da candidata. `world/refuge-lateral` conserva
1.1.0 da casa. Índices/catálogo/bindings foram regenerados, sem escolher
latest ou alterar releases existentes. O UID de lifecycle é o da candidata.

Os testes de lifecycle Brasa da integração anterior são preservados, incluindo
a observação limitada de 1500 ms do término cosmético após reanimação, sem
retirar assert ou estender o prazo de feedback. Os novos casos de grama se
somam a eles. As regras permanecem rules4/catálogo2 com os manifestos
históricos auditados; a identidade esperada é `adb2e79b…d418`.

Fechamento desta combinação: executar `tools/iterate.py --video`, baseline
`artifacts/harness/foli-pilot-final-20261105T032233100397Z-562688/`, fontes
congeladas e sem outra captura/import/engine em paralelo. Resultado e hash
exatos ficarão no relatório preservado e nos PRs. Não atribuir o verde remoto
individual a esta combinação. A CI #23 passou todos os sete grupos, mas é
somente de `c7f9ec18`.

GO técnico independente de arte/dorsais em draft, sem aprovação estética,
performance final ou autorização para promoção. Bloqueios de Brasa/casa/foco
já existentes na candidata não são considerados resolvidos por esta branch.
Folivel dorsal mantém marcha limitada; verso de Foslash continua bloqueado;
casts de corpo e lâmina pintada de Foslash continuam lacunas. Produto0.3.0.

## Tentativa preservada e novo congelamento

O full com vídeo de `61c6499` terminou failed, fontes intactas/hash
`0532788c209a875a774c0340c13933efd942f7cd0e56edba6839f1727d56c038`:
erro de tipagem da lista condicional no novo helper de movimento; timeout
30 s em integration/expedition na travessia da casa; timeout15 s de serial
de input em title. Os demais gates passaram, incluindo oito mutações,
14.417 checks de regras, 252 de save e matriz Web1.104/0 nos cinco formatos.
Tentativa: `artifacts/harness/grass-finals-combined-20261105T071146158298Z-5391fb/`.
Não foi aceitação completa.

`a9dc51e` troca somente a construção da lista tipada por literal+append,
conservando vistas/facings/asserts. Movimento passou315/0 isolado na branch
#24 antes do push. Nenhum número de regra ou pixel mudou por essa correção.

A instrumentação mínima de Session nesta branch de suporte registra a
condição/prazo na falha e guarda o primeiro estado disponível antes do PNG,
sem sobrescrevê-lo numa segunda captura. Mantém a exceção original, todos
os prazos e os três consumidores existentes. Sete contratos fake-page
passaram contra a fonte aplicada. A tecla pode continuar mantida durante o
PNG e só ser solta no finally do chamador; o diagnóstico não muda isso nem
resolve a travessia lenta. A causa das falhas Web não foi atribuída à grama.
A nova candidata recebe fechamento próprio com fontes congeladas.
