# Recompensa histórica da main 60b4e30

`combined_catalog4_main_reward_60b4e30.json` foi capturado na main intacta
`60b4e3045ebb9188f2a1f67771a8f6bf37d714f9`, antes de trocar para o PR #32.
Identidade: `expedition-rules-4`, conteúdo
`28b326e20a544fd37abc3958a6efabdf5714cfca1b59d8cfe6b1898e71b09221`.

Uma instância privada usa seed 42013, Lonaro vital UID 1, Verdálio resiliente
UID 2 e Tempestral resiliente UID 3. O encontro `clearing` começa pela API
normal; somente o HP do inimigo foi reduzido a 1 no checkpoint privado,
validado por `Expedition.restore`. As quatro seleções/conjuração registradas
geraram a recompensa através de `Replay.execute`. Nenhuma oferta foi
construída manualmente. Isso testa compatibilidade, não dificuldade/balanço.

As cinco ofertas reais da main são captura de Nisca em reserva, Foslash,
Folivel, Auravel e Zuldar, nessa ordem. Cada continuação foi executada na main
a partir da mesma recompensa: escolha real, snapshot de mapa, entrada real em
`thicket`, snapshot de combate. Os testes comparam todos os campos e somente
atualizam a identidade para a revisão corrente. A revisão de catálogo continua
4 e Lonaro não recebe finais aquáticas ao continuar esse save.

O teste passa a recompensa antiga pela persistência de dois slots, retoma cada
escolha e compara RNG, planos, cartas físicas, UID, passivas, HP e próximo
encontro. Também exige migração idempotente, fonte imutável e rejeição atômica
de um marcador de catálogo 5 falsificado.
