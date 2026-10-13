StartupEvents.registry('item', event => {
  // Fichas
  event.create('ficha_blanca').displayName('Ficha Blanca ($1)')
  event.create('ficha_roja').displayName('Ficha Roja ($5)')
  event.create('ficha_verde').displayName('Ficha Verde ($25)')
  event.create('ficha_negra').displayName('Ficha Negra ($100)').rarity('uncommon')

  // Premio especial
  event.create('boleto_dorado')
    .displayName('Boleto Dorado')
    .rarity('epic')
    .glow(true)
    .maxStackSize(16)
})