# Foli → Folife: IDs preservados e arte provisória

O nome da linhagem aprovado por Pedro é **Foli → Folife → Foslash / Folivel**.
Esta primeira fatia integra os nomes e descrições das duas formas já jogáveis.
O ID da espécie continua `moss`; as formas continuam `moss` e `verdalio`, e a
aresta continua `moss_to_verdalio`. Assim, descobertas, indivíduos e saves
existentes usam os mesmos registros. Atributos, poderes, traço, passivas e
comportamento de evolução continuam os do protótipo, sem novos valores canônicos.

Foslash (lâminas de folhas, direção ninja) e Folivel (furtivo, folhagem cortante
nos quatro membros, capaz de crescer e encolher) são nomes/conceitos aprovados;
suas formas e arestas ainda não são conteúdo jogável desta fatia.

## Arte fixada

O Resource da linhagem referencia os seguintes bindings de produção:

- `moss`: `umbrals/moss` → `assets/umbrals/moss/versions/1.0.0/manifest.json`, papel `portrait`.
- `verdalio`: `umbrals/verdalio` → `assets/umbrals/verdalio/versions/1.0.0/manifest.json`, papel `portrait`.

Estes releases são retratos estáticos: o runtime usa a mesma imagem em ambos os
lados e anima movimento, idle, ataque e defesa por transformações de apresentação.
Eles não declaram sprites direcionais ou clips de animação próprios. Caso um
conjunto animado seja criado, registre ambos os lados e os clips necessários
no release versionado, fixe-o no runtime-lock e valide pelo pipeline de assets.
Nenhuma arte é copiada para este pacote.

Os retratos existentes de Musgo/Verdálio são fallback visível, e não sprites
finais das lebres aprovadas. A Library resolveu `lebre-linhagem-v11.png`
(`libfile_a9b538efea20819186288121735d1a5c`) e
`lebre-silenciosa-refinada-v13.png`
(`libfile_5e6845c3842c81919a200b01a1b0c40f`), mas o helper oficial de
materialização falhou nas duas transferências. Nenhum pixel foi verificado
localmente; não houve importação, nova versão de asset nem troca de runtime-lock.
Consulte [escopo e pendências](../../../docs/grass-family-v04-cnt-01a.md).
