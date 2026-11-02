# Grimório como códex de roguelike

Proposta de UI/UX — 2026-11-01. Revisada após orientação do usuário: descoberta progressiva e todos os seres são Umbrals. Base: leitura da implementação e dos contratos do projeto. Não é uma auditoria visual: não foi possível capturar a interface nesta sessão. Nenhuma mudança de interface ou mecânica foi implementada.

## Objetivo

Abrir o grimório para acompanhar o conteúdo descoberto ao jogar, entender o que cada entrada revelada faz e seguir suas relações: Umbral → evolução → poderes → efeitos. A consulta deve funcionar fora de uma expedição e durante a pausa, sem depender do time atual.

## Diagnóstico da implementação

- `scripts/main.gd::_codex()` monta um modal genérico de largura nominal 1300, com três colunas fixas, uma arte por espécie, nomes das duas formas, trait e uma frase sobre a assinatura. Apenas Voltar é interativo. Não há seleção de entrada, categorias, busca nem ficha de poder.
- A galeria usa uma lista fixa de três IDs. Novas espécies no catálogo não entram automaticamente.
- A evolução aparece no texto, mas não tem retrato próprio nem comparação de efeitos nessa tela.
- O menu inicial oferece o grimório; a pausa oferece continuar, opções, ajuda e saída, sem acesso ao códex.
- O catálogo atual contém 3 espécies com 2 formas cada, 12 poderes, 5 passivas e 3 encontros. Não contém itens. Não tratar as 6 formas como 6 espécies.
- O layout horizontal sem área de rolagem específica merece verificação em 720p, 4:3 e texto ampliado. É um risco identificado no código, não um corte observado em captura.
- A identidade já está definida: bosque azul-esverdeado, tinta escura, pergaminho, ouro antigo e retratos originais. O redesign deve aproveitar essa direção.

## Estrutura proposta

Tela ampla dentro da stack existente, com cabeçalho e rodapé fixos e conteúdo rolável. Abrir diretamente em Umbrals; não interpor um painel de estatísticas antes do catálogo.

```text
GRIMÓRIO DO BOSQUE                  Buscar no grimório…    Fechar
────────────────────────────────────────────────────────────────
Categorias       Catálogo                      Ficha selecionada
                 Elemento / Forma              Arte em destaque
Umbrals          [Brasa] [Musgo] [Faísca]        Brasa · Fogo
Poderes          Retrato + nome + elemento      Forma base / Evolução
Passivas                                       Trait e efeito
Bestiário                                      Poderes relacionados
Glossário                                      Passivas possíveis
────────────────────────────────────────────────────────────────
Selecionar · Abrir detalhes · Voltar             3 espécies
```

Esquema de organização, não mockup visual aprovado. Distribuição inicial sugerida em tela larga: categorias 16%, galeria 34%, ficha 50%; validar com o conteúdo real. Com apenas três espécies, usar retratos generosos e evitar espaço vazio de uma grade dimensionada para dezenas de entradas.

Em 1024×768 ou com texto ampliado, reduzir a quantidade de colunas e abrir a ficha em uma subpágina. Voltar restaura categoria, filtros, rolagem e entrada selecionada. Nunca comprimir três painéis até o texto ficar ilegível.

## Conteúdo de cada categoria

| Categoria | Galeria | Ficha |
|---|---|---|
| Umbrals | Retrato, nome, elemento; espécies como unidade principal | Arte da forma, alternância base/evolução, trait com valores, três poderes iniciais, assinatura e passivas possíveis |
| Poderes | Arte, nome sem quebra forçada, custo e espécie de origem | Efeitos numéricos, estágio, proprietário compatível, condição de desbloqueio e links para os efeitos |
| Passivas | Nome e resumo do efeito | Regra completa, espécies compatíveis, exemplo e lembrete de que pertence ao indivíduo e permanece na evolução |
| Umbrals encontrados em combate | Integram a mesma categoria Umbrals | Não criar categoria de monstros ou bestiário; todos são Umbrals |
| Glossário | Termos pesquisáveis | Queimadura, escudo, energia, vínculo triplo, trait e passiva; duração e exemplo curto |
| Itens, quando existirem | Ícone, nome e tipo | Efeito, condições e origem, conforme os dados reais disponíveis |

Itens fazem parte da arquitetura desejada, mas a versão atual não deve apresentar uma categoria vazia como se fosse conteúdo jogável. Integrar a seção quando houver definições reais; sua criação envolve conteúdo e possivelmente regras além deste redesign.

## Fluxos principais

1. **Abrir e explorar:** menu ou pausa → Umbrals, com primeira entrada selecionada e ficha visível em tela larga. O foco inicial deve estar no catálogo, não no botão Fechar.
2. **Entender uma criatura:** selecionar Brasa → alternar para Ignivar → comparar trait e poderes → abrir Sol devorador. Não exigir fechar e reabrir o grimório.
3. **Consultar um poder:** categoria Poderes → filtrar por espécie, custo ou efeito → abrir a ficha → seguir o link para a espécie ou para Queimadura. Filtros de efeito devem aceitar poderes híbridos.
4. **Encontrar pelo nome:** busca global por nome, forma evoluída e termo de efeito, ignorando acentos e caixa; resultados identificam sua categoria. Estado vazio informa a busca e oferece limpar filtros.
5. **Retomar:** Voltar percorre o histórico de fichas; na raiz, fecha e restaura o foco da tela de origem. Ao abrir pela pausa, a expedição permanece pausada.

## Regras de informação

- O códex é preenchido progressivamente pelas descobertas do jogador. Registros desconhecidos mostram silhueta ou selo e “???”, sem revelar nome, efeitos ou evolução. Busca e links também respeitam esse estado.
- Poderes e evoluções têm descoberta própria; descobrir a espécie não revela automaticamente toda a sua ficha. Os gatilhos exatos de descoberta ainda precisam ser definidos na implementação.
- Persistir descobertas entre expedições faz parte do escopo principal. Contagens refletem apenas descobertas reais; os exemplos visuais usam progresso ilustrativo. Favoritos ficam para uma etapa posterior.
- A ficha de poder mostra “Valores da forma selecionada, sem passiva nem bônus de combate”. Usar `Content.power_stats()` para evitar números divergentes. Assinaturas só têm estágio evoluído válido; não mostrar seu valor bruto como se fosse o efeito final.
- Exemplo: Bola de fogo tem dano 12 na forma base e 17 na evoluída, antes de passivas e traits. Combustão aparece separadamente como efeito da espécie. Não prometer que dano de ficha equivale ao dano de toda conjuração.
- Trait é da espécie; passiva é do indivíduo. Mostrar apenas passivas compatíveis, respeitando `PASSIVE_POOLS`.
- A linguagem de ajuda hoje usa “grimório” também para poderes do time. Na navegação, distinguir “Grimório” (enciclopédia) de “Poderes do time” (consulta da run).

## Direção visual

Um arquivo botânico arcano: fundo de tinta escura, áreas de leitura estáveis, títulos em pergaminho, divisórias finas em ouro antigo e ornamentos discretos nos cantos. A floresta permanece como contexto periférico; não colocar parágrafos sobre textura contrastante.

Arte e nome lideram a ficha. Dados mecânicos vêm em blocos curtos de custo, dano, escudo, cura e queimadura; contexto narrativo, se for escrito, fica abaixo. Usar serifada em títulos e a fonte de corpo existente em descrições. Reaproveitar as artes das evoluções e dos poderes.

Seleção usa contorno e marcador, além da cor elemental. Foco de teclado deve ser distinguível de seleção. Ícones recebem rótulos; informações importantes não dependem de hover. Evitar animação obrigatória de virar páginas: transições breves e discretas, respeitando movimento reduzido e sem bloquear comandos.

## Implementação sugerida

1. Criar apresentação dedicada em `scripts/ui/codex.gd`; `main.gd` apenas abre a tela e conecta retorno. Manter `screen_stack` como dono de input/foco.
2. Derivar entradas de `Content.SPECIES`, `POWERS`, `PASSIVES` e `ENCOUNTERS`; ligar poderes às espécies por `powers` e `signature`. Preservar IDs estáveis, sem fabricar indivíduos de combate para consultar o catálogo.
3. Implementar galeria, ficha e links entre Umbrals e Poderes primeiro, com todas as entradas existentes. Adicionar passivas, glossário e acesso pela pausa no mesmo ciclo de conteúdo completo.
4. Acrescentar busca e filtros simples, histórico e restauração de foco. Lembrar a navegação na sessão; persistência entre sessões é opcional e posterior.
5. Integrar itens quando seu modelo existir. Implementar persistência versionada de descobertas e eventos de revelação; adiar apenas favoritos.

## Critérios de aceite

- Todas as entradas são representadas no catálogo, mas apenas descobertas revelam detalhes. O progresso persiste entre runs. Todos os seres são Umbrals, inclusive os encontrados como oponentes; a integração desses registros precisa respeitar os dados disponíveis.
- Cada ficha de Umbral permite chegar aos seus poderes; cada poder permite voltar à espécie.
- Trocar de forma atualiza arte, nome, trait, números e indicação de assinatura corretamente.
- Consulta não altera time, RNG, cartas, recompensas ou progresso da partida.
- Teclado e controle percorrem categorias, resultados e detalhes com foco visível, sem exigir mouse; voltar restaura o contexto anterior.
- Busca sem resultados tem recuperação explícita. Filtros ativos ficam visíveis.
- Cabeçalho, retorno e controles permanecem acessíveis em 1280×720, 1440×900, 1920×1080, 1024×768 e 2560×1080, inclusive com texto ampliado.
- Verificar contraste mínimo de 4,5:1 para texto de corpo, leitura sobre os fundos reais, rolagem e estados de foco. Nada disso foi medido nesta proposta.
- Ao implementar, executar `tools/iterate.py` com baseline, acrescentar os fluxos do códex à captura e inspecionar imagens reais; usar vídeo se houver mudanças de movimento.

## Próxima decisão de design

Validar a composição com uma captura atual e um mockup da tela Umbrals → Brasa, seguido da ficha de poder. A prioridade é provar que consultar e relacionar conteúdo ficou fácil antes de investir em ornamento, animações ou progressão de coleção.
