class Deck
  attr_accessor :deck, :last_card, :new_hand

  def initialize
    @deck = []
    @last_card
    make_a_deck
  end

  def make_a_deck # make the deck at the start of a round
    card_faces = [2,3,4,5,6,7,8,9,10,'J','Q','K','A']
    card_suits = ['C','D','H','S']
    4.times {deck.concat card_faces.product(card_suits)}
    self.deck = self.deck.shuffle
  end

  def deal_new_hand
    self.new_hand = self.deck.pop(2)
    return self.new_hand
  end

  def deal_card (player)
    self.last_card = self.deck.pop
    player.hands[player.hand_counter] << self.last_card
    display_card(player)
  end

  def display_card(player)
    puts
    puts "#{player.name} drew a: " + self.last_card.join("-").to_s
  end
end
