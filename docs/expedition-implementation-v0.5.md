# Primeira expedição — V05-RUN-01 / V05-SAVE-02

Estado: **implementação integrada e validada localmente**. Produto
0.3.0; o marco 0.4 conserva os critérios humanos e 0.5 ainda requer economia
e conteúdo. Não é uma run de 15–20 minutos já medida.

## Percurso jogável

Iniciar expedição → escolher primeiro vínculo → mapa → Clareira → captura ou
evolução → mapa → Mata fechada **ou** Nascente → Guardião → vitória/derrota.
A Mata inclui combate e sua recompensa; a Nascente cura até 25% do HP máximo
dos integrantes vivos, sem reanimar ou conceder recompensa. A escolha fecha a
outra rota. São defaults reversíveis adotados por delegação.

O mapa mostra formação/HP, mochila, estados dos caminhos, detalhes e confirmação.
Permite ajustar de um a três ativos antes do encontro. Uma passagem não cura
todos, recompõe cartas ou preenche o trio automaticamente. Nós concluídos não
podem ser repetidos para farmar.

## Save e retomada

Continuar expedição restaura o estado estável exato, inclusive uma rodada de
combate, com as mesmas cartas e intenção comprometida. Comandos ainda não
conjurados são limpos. Preferências e estatísticas permanecem separadas.

Novo jogo pede confirmação antes de substituir um progresso existente; cancelar
mantém o registro. A substituição aposenta o backup anterior. O treino de batalha
conserva o percurso anterior e não sobrescreve a expedição salva.

Dois registros com schema/checksum permitem recuperar uma geração válida.
Falhas são expostas; conclusão usa IDs para evitar contagem duplicada ou reabrir
um registro antigo já concluído. Web verifica o conteúdo gravado por leitura.
O [contrato](expedition-contract-v0.5.md) detalha estado e responsabilidades.

## Trabalho paralelo e integração

- TERRA 6.1: controlador, fronteira das regras, IDs e validação dos snapshots.
- LUNA: componente de mapa, foco, rolagem, texto ampliado e estados legíveis.
- TERRA 6.1: envelope do save, recuperação e revisão independente das falhas.
- TERRA 6.1: fixtures da cena e reprodução no navegador dos dois caminhos.
- Integrador: menu/telas/checkpoints/estatísticas, contratos e gate completo.

O primeiro preflight encontrou uma suposição de teste sobre vaga ocupada na
segunda captura. A escolha passou a seguir as vagas realmente disponíveis.
Uma revisão posterior reproduziu seleção da Nascente trocada pela Mata ao
pausar/retomar. O primeiro gate foi interrompido e preservado; seleção visual
agora tem estado explícito e regressão por pausa/opções. O segundo gate detectou
que o marcador visual não era reconstruído, embora a rota já estivesse preservada.
A construção do botão passou a respeitar a seleção, com três verificações nativas
do indicador e a mesma regressão no navegador. Os dois gates anteriores permanecem
registrados como interrompido/falhado; somente a execução final foi aceita.
Também detectou uma mensagem de falha de save apesar de bytes gravados no Web;
a verificação por leitura agora confere o resultado real. Tentativas e probes
originais estão preservados em `test-results/expedition-start/`.

## Validação e limites

O gate final passou; a revisão e a proveniência estão registradas abaixo.
Os testes dirigidos já cobrem os dois caminhos, conservação de donos/cartas,
RNG, retomada JSON, escrita interrompida, cancelar/substituir, isolamento do treino
e idempotência do resultado. Isso não substitui cinco primeiras sessões humanas,
desempenho no iPhone/Windows, controle físico ou audição em hardware.

O bioma usa um grafo curto fixo. Não há mercador, aprendizado, edição adquirível
de cópias, aquisição de relíquias/artefatos, eventos variados ou progressão do
Refúgio nesta fatia. O próximo incremento é V05-ECON-03, aproveitando a expedição
e suas transações. Persistência da loja entre runs (D20) continua uma direção
distinta a desenvolver em 0.6.

## Evidência final desta entrega

Validação integrada aprovada: `V05-RUN-01-release-20261030T025207741172Z`.
Fontes congeladas: `a55c5bcd80284213bef96384d47fc96878fea1198e9a36793dabdfc94acf2bf1`.
Pacote Web: `3c7e4b42b8ad7e57724827da12170ced5f47dc0d541959673183ff3f8f809fd7`.

- 14413 verificações de batalha, 444 UI, 109 de expedição/save/cena.
- 1641 verificações no navegador de treino e 383 na expedição.
  Quatro percursos de batalha e duas rotas de expedição; ambas chegam à vitória.
- Oito mutações representativas detectadas; cinco formatos na suíte de batalha
  e mapas com texto ampliado em 800×600 e 1600×900.
- A regressão de seleção da Nascente verifica pausa/opções/tamanho de texto
  sem trocar a rota selecionada ou consumir RNG; o marcador visual também é verificado.
- O pacote de hospedagem passou por 21 verificações de toque em 844×390:
  mapa, captura, descanso, exatidão da retomada e isolamento do treino.
- Probe suplementar: nove passes legais levam à derrota; snapshot terminal
  restaura sem reabrir a rota. É teste nativo, sem alegação de playtest humano.
- Web/Windows/Linux exportados e ZIPs verificados; inicialização/encerramento
  headless Linux aprovado. Windows e controle físico não foram exercitados.

`review-notes.json` registra os renders efetivamente inspecionados e limites.
O vídeo do treino cobre a batalha preservada; a nova expedição tem renders,
logs de entrada e testes de retomada, sem alegação de um vídeo próprio do mapa.
Texto continua pequeno em telas de celular; a interface permanece orientada a PC.

[Prévia privada](https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site) e
[novidades com capturas reais](https://umbral-ecos-do-bosque-teste.honestscarf2048.chatgpt.site/novidades.html).
Publicação privada concluída; audiência preservada. O commit da cópia Sites é
`2fb85d4a7a7a0fb15992bba2cf150fd03e19e191`. Proveniência em `private-deployment.json`.
A política de rede do executor impede uma visita autenticada ao host publicado;
o status terminal do Sites e o pacote final por HTTP local foram verificados.
Nenhum commit/push foi feito no repositório principal.

## Ajustes de UX ainda recomendados

A interface segue orientada a PC, com texto pequeno em celular. O mapa usa uma
bifurcação fixa e bastante espaço livre. Os totais do menu agregam treino e
expedição; o rótulo “expedições” deve virar “partidas” ou usar contadores separados
numa próxima fatia de UX. Isso não altera a retomada nem a proteção contra
contagem duplicada. As observações estão nas capturas e em `review-notes.json`.
