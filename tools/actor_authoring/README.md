# Requisitos de autoria de criaturas — V05-ART-01A

Primeira fatia isolada para ampliar o elenco da 0.5/0.6 com requisitos
reproduzíveis. O resultado observável é um relatório que separa idle, caminhada,
dano e origens de ataque existentes das pendências de produção. Não muda o jogo.
Segue os skills locais [Umbral](../../.agents/skills/umbral/SKILL.md) e
[Create Game Assets](../../.agents/skills/create-game-assets/SKILL.md).

## Rodar

Na raiz do repositório, com as [dependências de assets](../requirements-assets.txt):

```bash
python -m pip install -r tools/requirements-assets.txt
python tools/actor_authoring/validate.py tools/actor_authoring/examples/brasa-v1.json
python -m unittest tools.actor_authoring.test_validate -v

# Gate de requisitos: o exemplo atual retorna 1 porque falta caminhada.
python tools/actor_authoring/validate.py tools/actor_authoring/examples/brasa-v1.json --require-complete
```

Saída JSON determinística em stdout. Código 0: referências válidas, podendo
conter lacunas declaradas. Código 1: `--require-complete` encontrou lacunas.
Código 2: contrato, fonte ou dado inválido. `valid: true` não implica
`complete: true`; nenhum dos dois implica aprovação visual. Não há escrita de
assets, geração de animações, alteração de manifests ou promoção de runtime pins.

## Contrato v1

`profile-v1.schema.json` é um contrato de autoria separado do schema de módulos
de assets e do formato de saves. Uma mudança incompatível exige outro schema e
adaptador; não reescrever o v1 publicado. O único adaptador desta fatia é
`battle-motion-v1`, para os canais normalizados de `battle_motion.gd`:

- Fontes por `{id, version, role}` exatos, resolvidas nos manifests existentes.
  Reutiliza leitura JSON estrita, schema de módulo, caminhos seguros e integridade
  SHA-256/bytes do pipeline. Não busca `latest` nem consulta runtime-lock.
- Cada requisito `idle`, `walk`, `hurt` declara um track `{group, clip}` ou uma
  lacuna `{missing: "motivo"}`. Os três campos são obrigatórios; omitir uma
  necessidade não a satisfaz. Tracks precisam ter amostras numéricas finitas,
  escala positiva, 20 canais na ordem atual e variação real. Estados obrigatórios
  com amostras idênticas são rejeitados.
- `attacks` lista explicitamente os índices das performances a revisar para essa
  forma. Cada uma precisa de cast e reação, relógio ordenado dentro do cast,
  contatos válidos e origem anatômica explícita no nome de `parts[index]`.
  A lista não é um catálogo de poderes nem um teste de todos os golpes da espécie.
- Pivô de chão e pontos anatômicos usam coordenadas normalizadas da imagem.
  O relatório mostra o ponto de origem **antes da deformação**. A projeção em
  movimento continua pertencendo a `creature_rig.gd`; não foi duplicada aqui.

## Existente e pendente na base e151ba2

| Item | Evidência existente | Limite |
|---|---|---|
| Oito formas de batalha | `characters/battle-motion@1.0.0`, schema 1, 30 FPS | Malhas sobre arte existente; não são novas poses desenhadas. |
| Idle e dano | `states/0` e `states/3`, 97 amostras cada | Revisão de identidade e cadência continua visual. |
| Quinze casts e reações por forma | `attacks/0..14` com 97 amostras; `reactions/0..14` com 61 | O exemplo Brasa verifica somente 0, 1, 2; não declara cobertura de todos os sockets. |
| Origens do exemplo Brasa | Boca `mouth`, cauda `tail`, pata `fore`, com relógios de `woodland-elements@1.1.0` | O validador rejeita ausência mesmo quando o runtime teria fallback para boca. |
| Caminhada de criaturas | Nenhum track declarado no exemplo | Gap explícito `walk`; investida não foi renomeada para caminhada. |
| Viajante do refúgio | `characters/refuge-traveler@1.0.0/poses.json` tem idle/walk em frames | Outro formato. Este adaptador não valida nem reaproveita suas poses para criaturas. |

O teste de compatibilidade lê as oito formas publicadas e suas três variações
elementais principais (0–11 no conjunto). Os índices corporais 12–14 existem,
mas não são anunciados como sockets explicitamente validados por esse teste.

## Próximo Umbral

1. Use a autoria de espécie existente em `tools/umbrals.py` para conteúdo
   mecânico. Este perfil não cria uma espécie nem altera IDs, regras ou saves.
2. Produza arte/tracks e pontos anatômicos no fluxo de assets existente. Crie um
   módulo ou nova versão; preserve releases imutáveis, metadados e proveniência.
3. Copie o exemplo para um perfil de autoria e fixe as fontes/forma reais.
   Declare as lacunas antes de os arquivos existirem; não aponte para proxy ou
   animação de outra criatura para obter aprovação numérica.
4. Rode o validador e testes. Para auditar um catálogo em staging, `--root` pode
   apontar para outra raiz com `assets/domains.json`, schemas e módulos válidos.
5. Após produzir os estados, substitua os motivos por tracks reais. O gate
   completo verifica presença/estrutura; a semântica de caminhar, estabilidade
   de volume, apoio no chão e origem projetada exigem revisão em movimento.
6. Antes de integrar, rode a validação completa do pipeline e o harness do jogo,
   com revisão de imagem/vídeo. Este PR não adiciona locomoção ao runtime nem
   executa o exportador fixo `export_battle_performances.py` como fábrica genérica.

O CI próprio `actor-authoring.yml` executa os testes sem alterar o registro
compartilhado do harness. Integração futura nesse registro cabe ao integrador.
Próxima fatia: produzir e revisar um walk de criatura, então escolher seu
contrato de reprodução. Aprovação de arte, runtime e caminhada permanecem abertas;
a versão do produto continua 0.3.0. O integrador deve registrar este handoff no
roadmap ao integrar as frentes paralelas.
