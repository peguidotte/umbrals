# Fontes e manutenção

## Proveniência desta integração

Integração inicial em 2026-11-04, a partir do contexto consolidado da conversa com
Pedro entregue junto ao pedido de integração no repositório. O pedido explícito
foi guardar lore no projeto para que agentes a considerem ao implementar código.
A classificação de decisões neste diretório deriva desse contexto, não de uma
leitura dos PDFs ou de suposições sobre seu conteúdo.

| Fonte identificada | Papel | Estado nesta integração |
|---|---|---|
| `umbral-fontes-v02.zip` — Library `libfile_1f54516211148191b0007fcd1ebef3f6` | Fonte primária indicada; descrita no pedido como Markdown de mundo/jogo e imagens. | Materialização solicitada; transferência falhou com `library file transfer failed: download failed`. Não ficou um ZIP legível no executor; conteúdo não inspecionado nem copiado para o Git. |
| PDF de mundo — Library `libfile_9d6c89a1fb648191ba50be81e7361221` | Referência secundária identificada no pedido. | Não materializado nem lido. |
| PDF de jogo — Library `libfile_07f4408abb748191974706c1ff855b51` | Referência secundária identificada no pedido. | Não materializado nem lido. |
| Contexto consolidado de Pedro | Decisões, preferências e ressalvas fornecidas na delegação. | Lido e organizado em mundo, primeiro jogo e pendências. |
| Repositório, main `f67f73e` | Contratos e comportamento existentes. | Preflight com fetch confirmou main atual. AGENTS.md, skill local, README, roadmap, arquitetura/mapa/guidelines, autoria, harness, direção de arte v0.4, entrega do grimório e pontos pertinentes do catálogo/código inspecionados. |

Não há cópia dos documentos originais neste diretório. Os identificadores acima
permitem retomar o acesso autorizado; não são links relativos para arquivos
inexistentes. Nenhuma imagem foi integrada ou validada visualmente. Nenhum hash
de arquivo-fonte é informado porque os bytes não foram obtidos.

## Reconciliação quando a fonte primária estiver disponível

1. Materializar o ZIP pela Library, confirmar legibilidade, inventário e integridade
   e registrar versão e hash reais. Não inventar URLs nem conteúdo ausente.
2. Ler os Markdown de mundo e jogo integralmente. Manter a distinção das camadas.
3. Comparar as afirmações com as decisões explícitas de Pedro e com as ressalvas
   deste diretório. Nomes rejeitados, cosmologia, região, origem das cartas e
   detalhes exploratórios não passam a confirmados por estarem no pacote.
4. Registrar discrepâncias e propostas para revisão, com a localização na fonte.
   Arquivos originais eventualmente versionados devem ficar identificados como
   fontes de exploração, com entrada apontando para os status revisados.
5. Inspecionar pixels e registrar proveniência antes de integrar imagens;
   não substituir o alvo visual existente por referências exploratórias.
6. Atualizar este registro com o que foi efetivamente lido/importado. Não declarar
   a reconciliação concluída enquanto o pacote primário permanecer indisponível.
