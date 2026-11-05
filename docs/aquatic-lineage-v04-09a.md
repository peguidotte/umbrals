# V04-ART-09A — início da integração aquática

Base: main `1523d0e`. Objetivo desta fatia: escolher Lonlon, jogar com seus
poderes aquáticos e evoluir para Lonaro usando os contratos atuais, preservando
as expedições existentes. É uma entrega parcial da família aprovada; versão do
produto e marcos permanecem abertos.

## Decisões aprovadas

- Família: **Lonlon → Lonaro → Londraval (principal) / Lonelo (alternativa)**.
- Lonlon é uma lontra e controla livremente uma esfera de água destacável.
- Em Lonelo a esfera desenvolve vida própria, dependente da lontra; pode mudar
  de forma e agir ao seu lado. Dois ataques foram uma ideia, não uma regra de
  balanceamento fechada.
- Na referência `familia-agua-companheiro-azul-v10.png`, o painel direito é a
  alternativa aprovada. O núcleo do painel esquerdo foi rejeitado.

Fonte: decisões de Pedro repassadas na delegação de integração em 05/11/2026.
Referência Library: `libfile_2c296e23cd5c819189c30eaa74c3da82`.

## O que este rascunho integra

| Exibição | ID existente | Resultado |
|---|---|---|
| Lonlon | espécie/forma `dew` | Inicial de água, poderes e descoberta existentes |
| Lonaro | forma `mareveu` | Evolução existente `dew_to_mareveu` |
| Londraval | Ainda não registrado | Final principal aprovada, produção pendente |
| Lonelo | Ainda não registrado | Final alternativa aprovada, produção pendente |

Somente nomes e prosa mudam nos Resources da linhagem e de Maré lunar. As descrições usam o controle da água
confirmado, sem manter a origem na Fenda como cosmologia. Não há alteração de
atributos, traço, cópias, assinatura, natureza, resistências, RNG, rotas ou arestas.
A seleção inicial, rótulos de combate, recompensas, inspeção e grimório consultam
o mesmo catálogo. Saves, UID/passiva, cartas físicas e descobertas mantêm os IDs.

O digest mecânico permanece
`7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80`,
com `expedition-rules-3`. Não é necessária migração para esta mudança cosmética.
O `runtime-lock`, os registros compartilhados e os releases imutáveis ficam
intactos. O integrador pode combinar esta alteração ao Resource aquático sem
regenerar pins ou sobrescrever as outras famílias.

## Arte e comportamento ainda pendentes

A preparação oficial de materialização localizou a referência, mas o helper
atual da skill Library retornou `download failed`. Não foram obtidos pixels
legíveis locais e não foi usado um caminho alternativo de transferência.

Os sprites aquáticos antigos permanecem como fallback. Eles não representam
a lontra aprovada. O rig e as coreografias aquáticas existentes continuam
funcionando; isso não comprova os estados ou a origem dos golpes da nova arte.
Esta fatia não implementa esfera independente, duas entidades de combate ou
ataques extras, e não apresenta arte conceitual como sprite pronto.

Para completar as quatro formas: materializar e inspecionar as referências;
produzir corpo/esfera separados e seus pontos de emissão; validar repouso,
movimento, dano e conjuração nos dois lados; registrar versões e pins explícitos;
adicionar as duas arestas finais com decisão de compatibilidade dos saves;
capturar sua escolha e seus ataques no jogo. Os números e efeitos dessas finais
continuam sem balanceamento aprovado.

## Verificação e revisão

Antes da edição foram preservados checkpoints reais de combate, recompensa e
pós-evolução de uma run aquática, seed 42013. A comparação posterior deve restaurar
cada checkpoint exatamente, incluindo RNG, intenção comprometida, cartas,
ofertas, forma, UID e passiva; somente a consulta do nome passa a Lonlon/Lonaro.
A baseline da escolha inicial está em `artifacts/aquatic-before/`.

As nove verificações dos três checkpoints passaram. Catálogo, autoria e saves
passaram no run focado
`artifacts/harness/aquatic-focused-20261105T011851799497Z-e28226/`.
O fechamento completo e a revisão dos renders serão registrados ao final.

A primeira tentativa completa em `artifacts/aquatic-names/` foi interrompida
deliberadamente após detectar a descrição de Maré lunar ainda citando Marevéu.
Os gates nativos passaram, mas o percurso Web interrompido não é aceitação.
A descrição foi alinhada a Lonaro antes de reiniciar com fontes congeladas.
