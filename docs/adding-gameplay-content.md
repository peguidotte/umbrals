# Poderes, estados, itens e encontros

Leia também [architecture-guidelines.md](architecture-guidelines.md) e
[adding-umbrals.md](adding-umbrals.md). Os Resources registrados são definições estáticas:
nunca guarde quantidade, HP, equipamento ou duração restante dentro deles.

## Ordem e responsabilidades

1. `cast_evaluator.gd` valida propriedade/energia e lê condições do estado inicial.
   Fontes são ordenadas por `instance_id`, independentemente da ordem de seleção.
2. Passiva e trait modificam os efeitos básicos de cada poder. Limites por UID são
   compartilhados pela conjuração; não são reiniciados por carta.
3. `inventory.gd` aplica modificadores aditivos da fase `after_traits`, uma vez por
   UID equipado que produziu a operação exigida. O vínculo triplo é uma contribuição
   separada. Não existe um barramento de callbacks com ordem implícita.
4. `effect_resolver.gd` executa pedidos tipados, estados `after_cast`, ação inimiga
   se ele sobreviveu, e estados `after_retaliation`. A ordem de fontes é canônica.
5. `rules.project()` devolve estado e eventos sem escrever estado ou consumir RNG.
   `play()` confirma, descarta e compra cartas usando o RNG da expedição.

`player` significa o fôlego compartilhado do time; `enemy` é o único adversário atual.
Não existem HP individuais nem combate com múltiplos inimigos nesta implementação.

## Poder compartilhado e variante de forma

`content/umbrals/ember/powers/fireball.tres` contém ID, nome, descrição, arte e ação.
As duas formas referenciam essa mesma identidade. Cada variante em
`forms/<form_id>/powers/` declara custo, efeitos e assinatura por completo. A evolução
não aplica fórmulas ocultas e pode substituir/remover poderes.

Exemplo de variante com dano e compra de cartas:

```ini
[gd_resource type="Resource" format=3]
[ext_resource type="Script" path="res://scripts/catalog/power_definition.gd" id="power"]
[ext_resource type="Script" path="res://scripts/catalog/effect_definition.gd" id="effect"]
[ext_resource type="Resource" path="res://content/umbrals/ember/powers/fireball.tres" id="identity"]
[sub_resource type="Resource" id="damage"]
script = ExtResource("effect")
operation = "damage"
target = "enemy"
amount = 12
[sub_resource type="Resource" id="draw"]
script = ExtResource("effect")
operation = "draw"
target = "player"
amount = 1
[resource]
script = ExtResource("power")
identity = ExtResource("identity")
cost = 2
effects = Array[ExtResource("effect")]([SubResource("damage"), SubResource("draw")])
```

Operações atuais: `damage`, `block`, `heal`, `status`, `draw`. Condições atuais:
`always`, `target_burning`, `target_wounded`. Elas leem o início da conjuração;
aplicar queimadura agora não ativa uma condição de alvo já queimando nesse mesmo cast.
Nova combinação usa dados. Uma operação ou condição realmente nova exige implementação
pura e exemplo numérico independente no domínio, antes de qualquer código de UI.
Os accessors antigos `damage/block/heal/burn` são adaptadores para fixtures/traits e
cartas existentes; não são campos exportados paralelos aos efeitos.

Compra repõe a mão até seis e adiciona as cartas extras disponíveis, sem duplicar
instâncias. Prévia limita a quantidade ao estoque que poderá ser reciclado. A mão é
dimensionada pela quantidade; teclado 1–6 continua sendo atalho para as seis primeiras,
e cartas extras continuam acessíveis por mouse e navegação de foco.

## Estados e eventos

`content/statuses/burn.tres` é um exemplo completo. Um estado declara ID, nome,
operação por carga, duração (`-1` enquanto houver cargas), decaimento, limite,
empilhamento (`add`, `max`, `replace`) e fase do tick. Duração positiva conta ticks,
incluindo o primeiro tick na fase indicada após a aplicação. Trocas de cartas e uso
de itens não avançam esses relógios. Encontros novos limpam os estados.

O estado runtime guarda cargas, duração restante, alvo e origem. Um estado acumulado
por ID/alvo atribui seu tick à última aplicação/renovação; ele não mantém uma origem
por carga. Queimadura é a definição comum usada também por traits e passivas.

Eventos contêm fase, operação, ID e instância da fonte, UID, alvo, quantidade pedida/aplicada,
quantidade bloqueada, mudança efetiva, estado associado e ação/som quando pertinente.
Feedback agrupa eventos aplicados para números/áudio; não consulta poderes para
recalcular resultados. Histórico e logs conservam os eventos individuais. Prévia gera
outra lista, nunca grava o histórico. Overkill e cura excedente não contam como aplicados.

## Inventário e equipamento

`content/items/catalog.tres` lista os itens iniciais da expedição. Os exemplos reais são
`forest_tonic.tres` (uma dose, cura até 10) e `ember_charm.tres` (+2 dano uma vez por
conjuração do UID equipado). A relíquia começa desequipada. Use **BOLSA** durante a batalha.

`ItemDefinition` guarda texto, efeitos ou modificadores. `Inventory.ItemInstance`
guarda ID da instância, quantidade e UID equipado. A quantidade é a carga do consumível;
a relíquia atual não tem desgaste. Uso valida fase, existência, quantidade e mudança
real antes de gastar. Prévia, uso de item, cura de poder e cura inimiga compartilham o
mesmo executor. Usar/equipar não gasta rodada. Escudo concedido por item espera a próxima
conjuração; o escudo do jogador expira após seu revide.

Há uma relíquia por indivíduo. Transferir é explícito. Evoluir preserva o vínculo por UID;
substituir um indivíduo devolve o equipamento à bolsa. Itens persistem entre encontros e
reiniciam em nova expedição. Continuam em memória no fluxo do jogador: não foi adicionada uma opção de continuar run. O checkpoint validado de desenvolvimento preserva inventário/equipamento; veja [harness.md](harness.md).

## Inimigos, recompensas e ambientes

- `content/enemies/`: HP, arte e padrão ordenado de `EnemyAction`, cada uma com efeitos.
- `content/encounters/`: inimigo, ambiente, subtítulo e tabela de recompensa.
- `content/expedition.tres`: sequência explicitamente ordenada de encontros.
- `content/rewards/`: pool ordenado de capturas, espécie garantida enquanto ausente e cura.
  Pool vazio usa a ordem do catálogo de espécies, preservando os rolls anteriores.
- `content/environments/`: cenário, luz, vaga-lumes e faixas de áudio.

Defesa inimiga protege a próxima conjuração; cura respeita seu HP máximo. Uma morte
antes do revide cancela toda a ação inimiga. Os três inimigos atuais conservam HP e
intenções anteriores; Volt continua garantido pela tabela, sem seu ID nas regras de recompensa.

## Verificação obrigatória

`bash tools/check.sh` verifica schemas, referências, assets/proveniência, exemplos de
veneno/regeneração, condições, compra, defesa/cura inimiga, equipamento/evolução,
consumo, pureza/RNG, histórico, UI e mutações. `catalog_snapshot.gd` compara espécies,
expedição, itens e estilo entre fontes e PCK real. Não reative conversão binária sem
resolver o problema documentado de arrays perdidos na exportação.

Para mudanças visuais, execute a iteração completa com baseline e vídeo. Veja
[visual-style.md](visual-style.md) para a galeria. Testes de headless não aprovam a imagem.
