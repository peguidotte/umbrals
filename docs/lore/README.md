# Lore de Umbral — entrada para agentes

Esta documentação orienta conteúdo e implementações futuras. Ela separa o mundo
compartilhado do primeiro jogo e não altera as mecânicas da main atual (produto ainda 0.3.0).
A integração inicial usa o contexto consolidado da conversa com Pedro; a leitura
do pacote primário ainda está bloqueada, conforme [fontes](fontes.md).

## Ordem de leitura

1. [Mundo](mundo.md): premissas confirmadas que valem além do primeiro jogo.
2. [Primeiro jogo](primeiro-jogo.md): decisões e direções específicas da jornada.
3. [Pendências](pendencias.md): propostas, perguntas e limites de aprovação.
4. [Implementação](implementacao.md): como conciliar lore e contratos existentes.
5. [Fontes e manutenção](fontes.md): proveniência e reconciliação futura do pacote.

## Status das afirmações

| Status | Significado para implementação |
|---|---|
| Confirmado | Decisão de Pedro registrada no contexto consolidado; respeitar em conteúdo novo. |
| Direção preferida | Preferência ou ideia apreciada, ainda sem especificação fechada. |
| Proposta | Possibilidade exploratória; não tratar como fato do mundo. |
| Em aberto | Decisão ainda necessária; não preencher automaticamente. |
| Implementado | Comportamento observado no código; não comprova cânone narrativo. |

O texto de uma fonte exploratória não vira cânone por estar em Markdown ou PDF.
Decisões explícitas de Pedro orientam a classificação; se duas fontes divergirem,
registre a divergência e a evidência antes de propor a conciliação.
Decisões existentes no [roadmap](../roadmap.md), incluindo D01 e D46, não são
revogadas por esta integração. A [matriz de conciliação](implementacao.md) registra
as tensões e a distinção entre apresentação, sistema e narrativa.
Os [contratos técnicos](../architecture.md) continuam descrevendo o comportamento
atual. Uma divergência narrativa não autoriza alterar regras, saves, catálogo ou UI.

Para uma tarefa futura, leia os documentos pertinentes, cite as decisões usadas no
PR e separe ajustes autorizados de propostas que dependem de escolha de Pedro.
