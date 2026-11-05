# V04-CNT-01A — nomes da linhagem de grama

Pedro confirmou **Foli → Folife → Foslash / Folivel**, corrigindo explicitamente
a grafia para **Foslash**, e pediu integrar as quatro famílias ao jogo. Esta é
uma primeira fatia de apresentação da família de grama, sobre a main `1523d0e`.
Não conclui as quatro famílias nem as quatro formas desta linhagem.

## Entrega desta fatia

As duas formas já jogáveis da espécie `moss` passam a se chamar Foli e Folife.
A fonte é `content/species/moss/species.tres`: escolha inicial, captura,
batalha, inspeção, evolução e grimório consultam o mesmo catálogo.
As descrições apresentam a lebre que controla folhagem e folhas destacáveis
usadas como lâminas, sem inventar origem cósmica, relação humana ou valores novos.

| Contrato persistido | Mantido |
|---|---|
| Espécie | `moss` |
| Forma inicial / intermediária | `moss` / `verdalio` |
| Transição | `moss_to_verdalio` |
| Descobertas do perfil | Mesmos IDs |
| Gameplay | Mesmos atributos, naturezas, resistências, poderes e traço |
| Indivíduos e cartas | Mesmos UID, passiva, cópias e donos |
| Save | Mesmo ruleset e digest; não precisa de migração cosmética |

Os valores mantidos pertencem ao protótipo existente; não são novos números
aprovados para Foli ou Folife. `scripts/expedition/identity.gd` já exclui nomes
e prosa da projeção de gameplay. Não foram editados facade, regras, manifests
ordenados, registry de migração, registry do harness ou runtime-lock.

O teste existente do grimório agora consulta o nome real da forma ainda não
descoberta, para continuar verificando que Folife permanece oculta. A antiga
asserção literal de Verdálio deixaria de detectar esse vazamento após a renomeação.

A captura real também revelou o rótulo Musgo pintado na referência da galeria.
`scripts/ui/codex/gallery.gd` só reutiliza esse rótulo enquanto seu texto coincide
com o catálogo; Foli usa texto nativo visível. O teste de história verifica esse
nome nativo para impedir que a ficha e a galeria mostrem nomes diferentes.

## Arte e formas finais ainda pendentes

Foslash tem a direção ninja com lâminas de folhas. Folivel é a alternativa
furtiva, com folhagem cortante nos quatro membros e capacidade de crescer e
encolher. Os nomes e conceitos estão confirmados; novas formas, arestas e
efeitos jogáveis não foram registrados nesta fatia.

A Library resolveu as duas referências exatas:

- `lebre-linhagem-v11.png`: `libfile_a9b538efea20819186288121735d1a5c`.
- `lebre-silenciosa-refinada-v13.png`: `libfile_5e6845c3842c81919a200b01a1b0c40f`.

O fluxo oficial `prepare_materialize` retornou os arquivos, mas o helper atual
`library_file_transfer.py materialize` falhou nas duas transferências com
`library file transfer failed: download failed`. Nenhum pixel ficou legível
localmente. Não houve transferência alternativa nem criação de sprites a partir
de uma referência não vista.

Continuam os retratos de Musgo/Verdálio fixados anteriormente. Portanto a
apresentação visual da lebre está incompleta. Animações/idle/ataques do runtime
existente não comprovam poses ou origens anatômicas próprias da nova lebre.
Nenhum asset, release imutável ou binding compartilhado foi substituído.

## Verificação e integração

O preflight com fetch confirmou a main atual e checkout limpo antes da alteração.
Uma execução de base passou catálogo, save e navegação Web. A execução focada
`grass-alias-regressions` passou catálogo (19), autoria (2), compatibilidade (5),
save de expedição e história do grimório. Os relatórios completos e a aceitação
final ficam nas evidências do PR; testes focados não são aceitação completa.

Um checkpoint de teste criado na main anterior à edição restaurou após a
renomeação com a mesma identidade e todos os campos equivalentes, incluindo
RNG exato em strings, passiva e cópias de cartas. A comparação normaliza ambos
os lados pelo mesmo parser JSON, pois os números inteiros do engine e os números
decodificados do JSON têm representações textuais diferentes.

Próxima integração necessária: obter pixels das referências pelo fluxo oficial,
produzir e revisar assets próprios por forma e acrescentar Foslash/Folivel com
arestas explícitas e uma decisão auditada de compatibilidade. Essa etapa deve
ser coordenada com o integrador de migração/runtime-lock. O PR fica em rascunho
para revisão do pai, sem merge automático.
