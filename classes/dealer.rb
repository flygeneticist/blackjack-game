class Dealer < Player
  def initialize
    @kill_check = false
    @name = 'The Dealer'
    @hands = []
    @hand_counter = 0
    @value = []
  end

  def decide_next_move (casino)
    if self.value[self.hand_counter] <= 21
      if self.value[self.hand_counter] < 17
        casino.deck.deal_card(self)
        take_a_turn (casino)
      else
        stand
      end
    else
      bust
    end
  end
end
