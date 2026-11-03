# dew: arte fixada

O Resource da linhagem referencia os seguintes bindings de produção:

- `dew`: `umbrals/dew` → `assets/umbrals/dew/versions/1.0.0/manifest.json`, papel `portrait`.
- `mareveu`: `umbrals/mareveu` → `assets/umbrals/mareveu/versions/1.0.0/manifest.json`, papel `portrait`.

Estes releases são retratos estáticos: o runtime usa a mesma imagem em ambos os
lados e anima movimento, idle, ataque e defesa por transformações de apresentação.
Eles não declaram sprites direcionais ou clips de animação próprios. Caso um
conjunto animado seja criado, registre ambos os lados e os clips necessários
no release versionado, fixe-o no runtime-lock e valide pelo pipeline de assets.
Nenhuma arte é copiada para este pacote.
