# Umbral: arquitetura de assets de cartas

## Status e objetivo

Especificação para implementação, baseada na leitura do GitHub `peguidotte/umbrals`, branch main, em 2026-11-08. A implementação deve executar `python tools/harness.py preflight --fetch`, registrar o SHA real e reconciliar qualquer mudança posterior antes de editar. Esta investigação foi somente por conectores: não executou preflight, Godot nem testes e não alterou o repositório. Nomes de novos módulos e arquivos abaixo são proposta técnica, não arquivos já existentes.

Objetivo: cada carta mostrar a identidade da família do dono, o dono realizando aquele poder, o tipo/natureza do poder e o alvo selecionado. A mesma técnica pode produzir imagens diferentes para donos diferentes. Separar assets reutilizáveis sem achatar toda a carta em uma imagem e sem mudar combate, aprendizado, saves ou cópias.

## Referências visuais inspecionadas

- Original oficial fornecida por Pedro: `libfile_5c99f7cc1ff481919a251afd30d5d28d`, `CFF11D42-07D4-4E04-A26D-94E293511ACC.jpeg`.
- Refinamento final aprovado: `libfile_d3ebb3c8c5888191a652713b6cc5b870`, `exec-c30cf6dc-fafd-40df-b414-69a82af36de4.png`.

O refinamento é o alvo visual: molduras orgânicas douradas identificam famílias; o corpo da carta mostra o Umbral realizando o poder; faixas do título e nome recebem a linguagem cromática do poder; o nome inferior identifica o dono sem repetir seu retrato; a carta destacada apresenta miniatura do alvo no canto superior direito. Manter os textos renderizados pelo jogo. Não recortar títulos, custo, nome, alvo, controles ou brilhos de seleção do concept como pixels de produção. Os números, poses, nomes de ataques e destinatários desenhados no concept não constituem novos dados de gameplay. A mão recolhida e o destaque devem preservar os contratos de input, foco, acessibilidade e HUD, não importar literalmente dimensões do mockup.

Exemplo crítico: a referência mostra Lonlon com Lâminas de folhagem. O catálogo atual não permite a Lonlon aprender `thorn_lash` de natureza Bosque. Essa combinação pode existir como fixture isolada para provar composição visual; não conceder o poder, mudar sua natureza ou alterar `can_learn` para reproduzir a imagem.

## O que existe de fato

- Godot 4.6.3. `scripts/content.gd` é a fachada de conteúdo; `content/species/*/species.tres` e `content/powers/*.tres` são os donos dos dados. IDs são estáveis e diferentes dos nomes traduzidos.
- Quatro famílias/espécies: `ember`, `moss`, `volt`, `dew`. Quatorze formas: Brasa/ember e Ignivar/ignivar; Foli/moss, Folife/verdalio, Foslash/foslash e Folivel/folivel; Nisca/volt, Niscor/tempestral, Auravel/auravel e Zuldar/zuldar; Lonlon/dew, Lonaro/mareveu, Londraval/londraval e Lonelo/lonelo. Não usar a tabela resumida antiga do README para contagem ou nomes.
- Evolução é grafo explícito de arestas `from`/`to`, com ramos. Não inferir por índice, nome ou nível numérico. Niscor e Auravel têm Água secundária; Zuldar não tem, mas uma carta de água aprendida antes da evolução pode continuar pertencendo ao indivíduo.
- Há 18 poderes; aprendizado distingue `universal`, `nature` e `lineage`. `Content.can_learn` consulta natureza primária/secundária e assinatura da família. Evolução preserva e melhora cópias existentes, sem criar assinatura automática.
- `scripts/ui/power_card.gd` desenha uma Button. `configure` resolve `Content.power_stats`, efeito existente, `Assets.texture(power.art)` e retrato do dono. Hoje a arte principal é genérica do poder. `scripts/ui/hand.gd` controla o layout. `reference_card_frame.gd` é outro consumidor de UI e não deve ser substituído indiscriminadamente.
- Pipeline existente: releases imutáveis `assets/<domain>/<slug>/versions/<semver>/manifest.json`, schema v1, hashes/proveniência, dependências exatas, `assets/runtime-lock.json`, catálogo e `scripts/assets/binding_paths.gd` gerados. `Assets.texture`, `bound_file` e `manifest` já resolvem pins. Não criar catálogo concorrente ou usar latest/globs no runtime.
- O lock atual só aceita roles texture/audio/font como bindings diretos. Um JSON de apresentação pode ser role `data` de um módulo acessado com `bound_file`, mas não deve ser acrescentado como binding direto sem evolução explícita do gerador.

## Identidades e composição

Chave da ilustração: `(species_id, form_id, power_id)`. A família determina a moldura; `form_id` admite override explícito da moldura e escolhe a aparência do dono. A identidade de indivíduo/UID permanece em gameplay e UI, nunca gera nova imagem por cópia. Duas cartas da mesma forma e poder compartilham textura, mesmo com passivas, UID ou dano diferentes.

Camadas, atrás para frente:
1. Fundo e sombra da carta.
2. Ilustração da combinação, recortada em área de arte definida.
3. Moldura da família, com eventual override da forma.
4. Ornamentos/faixas do poder por `power.nature`, nunca pela natureza do dono.
5. Título, nome do dono, custo e informações de efeito renderizados como texto/dados de UI.
6. Seleção, bloqueio, foco e indicadores existentes.
7. Badge do alvo selecionado, com miniatura da forma e indicação de contexto pertinente já existente.

Uma família pode reutilizar uma moldura em todas as formas por escolha editorial explícita. Isso não é fallback por falta de trabalho. Já a arte de combinação não pode substituir silenciosamente a forma adulta por bebê ou o dono por outra espécie. Retrato do alvo é reutilizável por forma, não imagem por par atacante-alvo. Não gerar imagens para todas as combinações de alvos. A arte de cura pode ser narrativa, mas não prometer um alvo específico diferente do badge atual; preferir composição sem destinatário identificável quando necessário.

## Organização proposta

Usar os domínios existentes, sem criar `cards` como novo domínio por conveniência:
- `ui/power-card-system`: composição, recortes, métricas, estados e metadados da apresentação.
- `ui/card-frame-moss`, `ui/card-frame-dew`, `ui/card-frame-volt`, `ui/card-frame-ember`: molduras e variantes publicadas independentemente.
- `ui/card-nature-forest`, `ui/card-nature-water`, `ui/card-nature-fire`, `ui/card-nature-lightning`: faixas/ornamentos. Não inventar naturezas.
- `umbrals/card-art-<form-slug>`: arte de cada forma, com roles por poder, por exemplo `power-thorn-lash`, `power-root-wall`. IDs com hífens conforme schema do asset; IDs do catálogo continuam com underscore. Não inferir a conversão no runtime: referências explícitas.
- `umbrals/card-target-<form-slug>`: miniatura. Pode reutilizar uma role de release já existente se passar revisão de enquadramento e legibilidade, sem duplicar pixels.

No módulo `ui/power-card-system`, incluir `files.layout` ou `files.presentation` como `kind: data` e uma textura visual realmente usada, por exemplo `files.selection`, que serve ao binding `ui/power-card-system`. `Assets.bound_file("ui/power-card-system", "presentation")` obtém o JSON sem violar o contrato do lock. Dependências do módulo fixam os releases referenciados. Não editar o schema de módulo v1 para acomodar campos arbitrários: o JSON possui schema próprio novo `card-presentation-v1.schema.json`; caso um contrato realmente incompatível do pipeline seja necessário, criar v2 explicitamente.

O JSON de apresentação deve conter:
- `schema_version`, versão compatível do layout e referência/proveniência visual.
- `families`: species ID -> moldura padrão + mapa `form_overrides` opcional.
- `power_styles`: nature ID -> faixas, ornamentos, tokens de cor e contraste.
- `illustrations`: species -> form -> power -> referência exata `{id, version, role}` e status editorial.
- `target_portraits`: form ID -> referência exata + crop/focal point normalizado; suporte equivalente para inimigos fora do catálogo de espécies.
- `layout`: aspecto, margens/zonas seguras, região da arte, âncoras de título/nome/custo/alvo e regras de texto.
- `coverage`: escopo de produção escolhido, combinações opcionais de demonstração e inventário explícito de pendências para desenvolvimento.

Releases utilizados por produção precisam ser production e todas as referências precisam corresponder às dependências exatas do módulo. Os dados não contêm dano, elegibilidade ou efeitos. Evitar duplicar o catálogo de gameplay no manifesto visual.

## Runtime

Criar `scripts/ui/card_presentation.gd` como adaptador puro de apresentação e `scripts/assets/card_visual_catalog.gd` como resolvedor fino. O primeiro recebe o card, dono e informação de alvo já filtrada pela aplicação; produz um view model. O segundo resolve somente referências validadas, caches e diagnóstico. `power_card.gd` consome o resultado e continua emitindo intent como Button; não virar dono de regras ou aprender poderes. Integrador confirma limites no mapa de arquitetura e preserva baseline.

Métodos sugeridos: `resolve_owner_visual(species_id, form_id, power_id)`, `resolve_target_visual(target_view)`, `prewarm(keys)`, `coverage_diagnostics()`. Retorno inclui arte, moldura, estilo, retrato e `missing_entries`; não substitui identidade do dono. O mesmo resolvedor deve servir mão, inspeção e visualizações de pilhas onde cartas são mostradas.

Cachear por referência exata, não por UID. Aquecer apenas formas/poderes visíveis e próximos da mão; nunca carregar todas as ilustrações ao abrir o menu. Não fazer I/O em `_draw`. Invalidar seleção de apresentação quando muda `form_id`, poder ou pin do conjunto; evolução troca arte sem trocar UID/card instance. Derivar efeitos e custo das APIs existentes. Não persistir referências de textura dentro de saves.

Alvo: usar slots semânticos e plano público existente. O badge atualiza ao trocar/cancelar alvo e quando o alvo visível muda. Área/slots vazios/sem seleção precisam de representação neutra ou indicação de área, sem inventar um único destinatário. Não revelar plano oculto, previsão privada ou futuro destinatário de inimigo. Indivíduos iguais continuam distinguíveis pelo nome/UID/contexto existente em detalhes acessíveis. O pequeno número e sinal + do concept não podem redefinir custo, contagem ou efeito sem semântica existente verificada.

## Cobertura e fallback

Gerar a matriz necessária a partir do catálogo real exportado pelo Godot, não de regex frágil nem lista manual. Incluir:
1. Poderes iniciais em cada forma alcançável, preservados pela evolução.
2. Poderes aprendíveis na forma conforme API atual.
3. Fechamento transitivo dos poderes legalmente adquiridos em formas ancestrais e retidos após evolução.
4. Entradas de compatibilidade necessárias a saves suportados e fixtures legítimas, sem usar o validador visual para alterar as regras.

Na main lida: 42 combinações de poderes iniciais (14 formas × 3), 70 combinações aprendíveis por forma considerando assinaturas e natureza secundária. O fechamento de Água de Niscor para Zuldar acrescenta 3, total esperado 73, sujeito à confirmação pelo exportador real e compatibilidade. Não usar 14 × 18 como requisito cego. Exemplo Lonlon/Bosque fica fora dessas contagens de produção.

Validação tem dois modos claramente distintos:
- Desenvolvimento: cada ausência produz diagnóstico estruturado, placeholder marcado ARTE PENDENTE e resumo de pendências. Pode usar ícone do poder e nome correto como placeholder, mas nunca parecer arte final do dono. Ausência de moldura/forma não escolhe uma família parecida. Form override ausente usa moldura padrão somente quando isso foi a escolha registrada da família.
- Produção: qualquer ausência na matriz exigida, placeholder, referência prototype/draft, textura inválida ou pin faltante falha no gate de build/export. Uma promoção parcial só pode cobrir explicitamente um escopo alcançável e não pode deixar outras cartas acessíveis fingindo prontidão. Runtime ainda mantém placeholder seguro e erro único por chave para falhas inesperadas, sem crash nem silêncio.

Relatório: total exigido/coberto/aprovado, lista por família/forma/poder, retenções evolutivas, demonstrações não jogáveis e assets órfãos. Reutilização deliberada entre combinações exige declaração e motivo, revisão visual e identidade correta. Proibir herança automática de ilustração pela família.

## Autoria, armazenamento, custo e versões

Produzir ilustrações sem texto nem UI, com zonas seguras e enquadramento que funcione na carta pequena e ampliada. Molduras com alpha; miniaturas com recorte/focal point próprios. Dimensões finais devem ser fixadas após teste real de 720p, zoom e texto ampliado. Ponto inicial a medir, não requisito artístico definitivo: arte 512×640 ou equivalente; miniatura 128×128/256×256; componentes de moldura separados ou atlas pequeno. Evitar um atlas monolítico do catálogo inteiro.

Custo dominante é arte por combinação: `C = A*c_arte + F*c_moldura + V*c_variante + T*c_estilo + P*c_retrato + revisão/retrabalho`. A=matriz real, F=4, T=4, P≥14 mais inimigos-alvo, V opcional. Cópias, passivas, UIDs e alvos não multiplicam A. Sem preços de fornecedor confirmados, não inventar valor em reais ou dólares. Planejar piloto de uma família com dois poderes e duas formas; incluir compartilhamento de poder em duas famílias como fixture. Só expandir após aprovação do resultado em tela.

RGBA 512×640 custa aproximadamente 1,25 MiB decodificado por ilustração; 73 imagens somam aproximadamente 91 MiB antes de mipmaps/overhead. Esse não é tamanho comprimido/download. Medir memória residente com cache limitado e concorrência de telas. Assets atuais impõem 16 MiB por arquivo e dimensões RGBA até 4096; manter limites existentes. PNG/WebP lossless conforme importer comprovado; não impor compressão destrutiva em texto ou bordas. Masters/reviews originais com proveniência ficam fora do export conforme padrão existente. Não introduzir LFS, CDN ou armazenamento remoto sem necessidade medida e decisão de infraestrutura.

Cada promoção cria nova versão imutável. Patch corrige compatibilidade visual; minor adiciona roles compatíveis; major muda recorte/métricas/contrato de layout. Novo conjunto não muda pin sozinho. Atualizar runtime-lock deliberadamente, regenerar catálogo/bindings e registrar revisão. Rollback é repin para conjunto anterior compatível. Mudança cosmética não incrementa ruleset, não invalida save nem reescreve IDs.

## Migração em fatias

1. Documentar spec e referências/proveniência; registrar SHA/base e owners. Integrador único para lock, generated files e harness registry.
2. Extrair matriz determinística de apresentação e testar cobertura sem mudar runtime. Adicionar schema, resolvedor, testes e relatório.
3. Criar piloto modular explicitamente prototype e uma galeria/fixture isolada. Provar família vs natureza do poder, adulto vs bebê, alvo, estados e escala.
4. Promover piloto após inspeção e integrar `power_card.gd` com feature/escopo de desenvolvimento explícito. Preservar ícones `power.art` para seus outros consumidores. Não apagar assets/releases existentes.
5. Completar/promover todas as combinações exigidas antes de habilitar o conjunto em produção. Ajustar mão apenas se necessário para reproduzir a aprovação e legibilidade, sem ampliar a tarefa para redesenhar arena.
6. Remover caminho legado da carta somente depois de teste de equivalência funcional e migração visual; manter releases antigos e rollback. Atualizar docs/assets, content-authoring, roadmap e evidências reais, sem declarar arte ou marco concluído antes da revisão.

## Testes e aceite

Python/schema/pipeline: referências inválidas, duplicatas, path traversal, colisão de nomes normalizados, hash/tamanho/alpha/crop incorretos, dependência ausente/cíclica, pins exatos, imutabilidade, generated files stale, nature/style desconhecido, placeholder em produção e cobertura incompleta. Teste negativo explícito precisa provar que o gate falha.

Godot: todas as referências resolvem após import e em export empacotado; `Texture2D` não nula; cachê compartilha imagens entre cópias; evolução conserva carta/UID e troca apenas visual; ramos usam IDs; Niscor→Zuldar conserva cobertura de poderes de Água; ausência tem fallback marcado; unknown form nunca vira ember silenciosamente; títulos e nome cabem com texto ampliado.

Regressão de input/estado: mouse, teclado, controle simulado e toque; foco/hover, escolhido/aiming, sem ações, KO bloqueado, cancelamento, repetição, alvo único/pares/todos/vazio, troca de ocupante e modal acima da carta elevada. Manter reduced motion; contraste e forma/símbolo além de cor. Testar mesmo poder com donos diferentes, poder de natureza diferente da família, mesmas cópias com stats diferentes e formas finais largas. Nenhum vazamento de intenção inimiga.

Gameplay/save: snapshot, RNG, ordem, custos, ações, alvos e decks idênticos antes/depois para os mesmos inputs; saves antigos e novos continuam carregando. Não mover assets para o fingerprint determinístico de gameplay nem alterar compatibilidade de regras por estética.

Harness: registrar testes em `tools/harness_lib/registry.py`; rodar validators do conteúdo e assets, focused suites, `bash tools/check.sh`, gates de export/packed-catalog e `python tools/iterate.py --label <slice> --goal '<objetivo observável>' --baseline <evidência>`; incluir vídeo se movimento mudar. Revisar capturas reais nos cinco formatos existentes, 720p, 4:3, ultrawide e texto ampliado. Headless pass não é aceite visual. Preservar falhas e não regenerar baseline para esconder regressões. GitHub Actions permanece pausado; não reativar como efeito colateral.

Aceite final: conceito reproduzido sem textos rasterizados; matriz exigida 100% coberta e revisada; nenhum fallback de produção; assets exatos/provenientes/imutáveis; custo/memória medidos; save e combate inalterados; regressões locais e export reais aprovados; referência e mudanças documentadas. Produzir relatório de verificações passadas, falhadas e não executadas, e screenshots de antes/depois, sem confundir testes com aprovação estética.

## Fontes verificadas

- https://github.com/peguidotte/umbrals/blob/main/AGENTS.md
- https://github.com/peguidotte/umbrals/blob/main/docs/assets/README.md
- https://github.com/peguidotte/umbrals/blob/main/docs/content-authoring.md
- https://github.com/peguidotte/umbrals/blob/main/scripts/content.gd
- https://github.com/peguidotte/umbrals/blob/main/scripts/ui/power_card.gd
- https://github.com/peguidotte/umbrals/blob/main/scripts/ui/hand.gd
- https://github.com/peguidotte/umbrals/blob/main/scripts/assets/catalog.gd
- https://github.com/peguidotte/umbrals/blob/main/tools/asset_pipeline.py
- https://github.com/peguidotte/umbrals/blob/main/tools/harness_lib/registry.py
- https://github.com/peguidotte/umbrals/tree/main/content/species
- https://github.com/peguidotte/umbrals/tree/main/content/powers
