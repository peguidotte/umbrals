# Fontes e manutenção

## Proveniência desta integração

Integração inicial em 2026-11-04, a partir do contexto consolidado da conversa com
Pedro entregue junto ao pedido de integração no repositório. O pedido explícito
foi guardar lore no projeto para que agentes a considerem ao implementar código.
Naquela etapa, a classificação derivou desse contexto, sem leitura dos PDFs.
Em 2026-11-08, a revisão V04-LORE-02 conferiu integralmente o texto dos dois PDFs
pela Library e conciliou os pontos abaixo com as decisões posteriores. A revisão
usa a main `f29752cac7d6525865091896a1466eb65a490c9c`, confirmada por fetch; não
altera gameplay, prosa do catálogo, saves, assets ou decisões posteriores da casa
inicial de Pietro.

| Fonte identificada | Papel | Estado após a revisão textual |
|---|---|---|
| `umbral-fontes-v02.zip` — Library `libfile_1f54516211148191b0007fcd1ebef3f6` | Fonte primária indicada; descrita no pedido como Markdown de mundo/jogo e imagens. | Materialização solicitada; transferência falhou com `library file transfer failed: download failed`. Não ficou um ZIP legível no executor; conteúdo não inspecionado nem copiado para o Git. |
| `umbral-mundo-v02.pdf` — Library `libfile_9d6c89a1fb648191ba50be81e7361221` | Referência textual do mundo. | Texto integral lido em 2026-11-08: 13 páginas, 607 linhas extraídas, sem continuação pendente. Não materializado; imagens não inspecionadas. |
| `umbral-jogo-v02.pdf` — Library `libfile_07f4408abb748191974706c1ff855b51` | Referência textual do primeiro jogo. | Texto integral lido em 2026-11-08: 8 páginas, 338 linhas extraídas, sem continuação pendente. Não materializado; imagens não inspecionadas. |
| Contexto consolidado de Pedro | Decisões, preferências e ressalvas fornecidas na delegação. | Lido e organizado em mundo, primeiro jogo e pendências. |
| Repositório, main `f29752c` | Decisões posteriores e contratos existentes. | Fetch confirmou a base atual em 2026-11-08. D01/D02, V04-BAT-03A, seleção de quatro opções e início com um indivíduo conferidos. `f67f73e` foi a base da integração inicial, não a main atual. |

Não há cópia dos documentos originais neste diretório. Os identificadores acima
permitem retomar o acesso autorizado; não são links relativos para arquivos
inexistentes. Nenhuma imagem foi integrada ou validada visualmente. Nenhum hash
dos PDFs ou ZIP é informado porque seus bytes não foram obtidos. Leitura textual
não confirma integridade binária, disposição visual nem conteúdo das imagens.
O ZIP não foi reinspecionado ou importado nesta revisão.

## Evidências da conciliação textual

As páginas abaixo são as páginas dos PDFs v0.2, não linhas do repositório. Elas
localizam o texto e seu status; ler um PDF não aprova todas as suas propostas.

| Ponto | Evidência e status na fonte | Aplicação documental |
|---|---|---|
| Ecologia e evolução | Mundo p. 8, “Criaturas que pertencem ao mundo”, **base estabelecida**: vida comum, herbívoros, predadores e evolução da representação. | [Mundo](mundo.md): explicitar a base sem impor simbolismo único ou regra mecânica de evolução. |
| Vínculos | Mundo p. 8, “Cartas e vínculos”, **base estabelecida**: motivo, ações, força/conquista e possibilidade de recusar/partir. Provas específicas e interface são exploração/aberto na mesma página. | Distinguir relação narrativa de medidores, porcentagens e testes de obediência não aprovados. |
| Tecnologia | Mundo p. 9, “O que vem antes da tecnologia”, e p. 13, **estabelecido**. | A precedência de tecnologias análogas não explica toda invenção humana. |
| Fauna comum | Mundo pp. 9 e 13, **aberto**. | Não concluir que os Umbrais substituem todos os animais comuns. |
| Equipes e fracasso | Jogo p. 7, “O que já está estabelecido”, e p. 8: equipe nova, sem retorno integral como coleção permanente, reencontros especiais e continuidade do protagonista. | [Primeiro jogo](primeiro-jogo.md): preservar D01 e distinguir nova run de retomada. Capacidades permanentes, preparação tática e retirada/resgate estão na solução proposta, não são reset aprovado. |
| Lendário mental | Jogo p. 2, “Domínio mental preferido”, e p. 8, “Direções apreciadas”. | **Direção preferida**; atenção compartilhada, relés, identidade, poderes e mecanismos continuam propostas ou perguntas abertas. |
| Organização e campeã | Jogo p. 3 mantém em aberto quanto poder a organização já usa; p. 4 chama a campeã aliada de proposta; p. 8 lista motivos, hierarquia e papel da campeã como abertos. | [Pendências](pendencias.md): não canonizar rede, hierarquia ou alinhamento da campeã. |
| Escolha inicial | Jogo pp. 5 e 7 registram a preferência antiga por três. A orientação posterior, reafirmada no pedido desta revisão, é quatro opções. O [contrato V04-BAT-03A](../natures-status-reactions-v0.4.md), seção “Disponibilidade pela run”, documenta quatro opções e início com um. | Tratar três como histórico superado. [Content.STARTERS](../../scripts/content.gd) tem quatro IDs; [Rules.new_run](../../scripts/rules.gd) cria um indivíduo, não quatro companheiros. |

A conciliação textual destes pontos está preparada. A conferência do pacote
primário completo continua pendente; não foi estabelecida equivalência entre
os PDFs e os Markdown/imagens do ZIP.

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
