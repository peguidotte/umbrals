# CI do Umbral

O workflow **Umbral — validate and build** roda em pushes, pull requests e execução manual. Ubuntu 24.04, Godot 4.6.3, Python 3.12 e as dependências do browser são fixados; as actions oficiais são fixadas por commit, com a versão correspondente ao lado. Ferramentas e caches ficam fora das fontes do jogo. Uma atualização na mesma branch cancela a execução anterior.

O job `quick-checks` executa arquitetura e testes headless com a engine (`install_godot.py --engine-only`) e Pillow para integridade dos assets, preservando `umbral-fast-checks`. O job dependente `validate` executa a iteração completa e os builds em outro runner. Ele repete os checks para vincular as próprias evidências às fontes; nenhum gate é dispensado.

## O que precisa passar

1. Limites arquiteturais (com dezenove regressões negativas), catálogo, projeção pura, ciclo de vida e origem e integridade dos assets, regras, simulações, mutações, UI e input nativo.
2. Export Web e jogadas reais no Chromium: opções, recarga rápida, combate, vitória, captura, evolução, substituição e todos os formatos de tela do contrato de UX.
3. Export e empacotamento Web, Windows e Linux, com validação dos ZIPs e SHA-256.
4. Inicialização e encerramento gracioso do executável Linux, rejeitando erros e vazamentos reportados pelo Godot.

O registro único `tools/harness_lib/registry.py` define os gates para wrappers locais e CI. O fechamento exige `scope=full`, cobertura completa, oito cenários aprovados e a matriz de cinco formatos. Uma execução focada nunca passa pelo gate de entrega. Importação/exportação usam cache validado; testes comportamentais completos rodam novamente.

O resumo da execução mostra verificações realmente executadas, etapas, formatos de tela, capturas e checksums dos builds. Uma suíte vazia ou uma matriz incompleta falha. A causa de falhas do harness aparece como anotação do GitHub e no resumo; logs e evidências são preservados mesmo quando a validação falha. Não há repetição automática para esconder falhas.

## Baixar e revisar

Na execução do GitHub Actions, baixe **umbral-evidence** para obter `test-results/`, o relatório de cada tentativa, capturas e vídeo. O `review-standalone.html` inclui as imagens. Para o vídeo, extraia `review-bundle.zip` e abra seu `index.html`. **umbral-builds** contém os três ZIPs jogáveis e `manifest.json`. Os artifacts são retidos por 14 dias; uma nova execução pode regenerá-los.

Para reproduzir localmente:

```bash
source tools/environment.sh
python tools/install_godot.py
python -m pip install -r tools/requirements-browser.txt
python -m playwright install --with-deps chromium
python tools/iterate.py --label ci-local --video --report-file test-results/ci-run.json
bash tools/build.sh Windows
bash tools/build.sh Linux
python tools/package.py
builds/linux/Umbral.x86_64 --headless -- --smoke-exit
python tools/ci_report.py --report test-results/ci-run.json
```

## Regressão de persistência Web

O primeiro CI detectou perda das opções de acessibilidade após recarregar a página. O arquivo virtual já tinha sido atualizado, mas sua sincronização com IndexedDB era assíncrona. A implementação usa gravação síncrona em `localStorage` para preferências e estatísticas, mantendo os arquivos antigos como fallback de leitura. O harness recarrega logo após as alterações, antes de capturas ou esperas extras, e verifica tanto ativar quanto desativar as opções. O teste de estatísticas após recarga também permanece.

Passar no CI demonstra essas validações e a exportação. Windows ainda exige execução no Windows; controle físico, áudio, desempenho em hardware, revisão visual e diversão exigem avaliação própria. O workflow não publica releases nem envia o jogo à Steam.
