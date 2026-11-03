# moss: arte fixada

O Resource da linhagem referencia os seguintes bindings de produção:

- `moss`: `umbrals/moss` → `assets/umbrals/moss/versions/1.0.0/manifest.json`, papel `portrait`.
- `verdalio`: `umbrals/verdalio` → `assets/umbrals/verdalio/versions/1.0.0/manifest.json`, papel `portrait`.

Estes releases são retratos estáticos: o runtime usa a mesma imagem em ambos os
lados e anima movimento, idle, ataque e defesa por transformações de apresentação.
Eles não declaram sprites direcionais ou clips de animação próprios. Caso um
conjunto animado seja criado, registre ambos os lados e os clips necessários
no release versionado, fixe-o no runtime-lock e valide pelo pipeline de assets.
Nenhuma arte é copiada para este pacote.
