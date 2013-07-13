class Cashier
  def initialize(dealer, player_queue)
    @player_queue = player_queue
    @dealer = dealer
  end

  # handles all of the money exchanges for the players who've not busted at the end of the round.
  def standard_win (player)
    winnings = player[1].wager * 2 # pays out 2:1
    player[1].bank += winnings
    puts "#{player[1].name}: won $#{winnings} and now has $#{player[1].bank} total."
  end

  def standard_loss (player)
    puts "#{player[1].name}: lost $#{player[1].wager} and now has $#{player[1].bank} total."
  end

  def settle_scores
    dealer_score = @dealer.value[0]
    @player_queue.each do |player|
      player[1].value.each do |player_score|
        if player_score == 100 # player surrendered
          self.bank += self.wager/2
          puts "#{name} surrenders and recieves $#{wager/2}. Bank left: $#{bank}."
        elsif player_score > 21 # player lost to dealer
          standard_loss (player)
        elsif player_score == 21 && player[1].hands[player[1].hand_counter] == 2 # player got Blackjack
          puts "#{player[1].name} got blackjack!"
          winnings = (player[1].wager + player[1].wager*(3.0/2.0)).to_i # pays out 3:2
          player[1].bank += winnings
        elsif dealer_score > 21 # dealer busts. all other players not busted win.
          standard_win (player)
        else # player score <= 21
          if player_score > dealer_score
            standard_win (player)
          elsif player_score == dealer_score
              winnings = player[1].wager # pays back player's wager
              player[1].bank += winnings
              puts "#{player[1].name}: pushed and got back the bet of $#{winnings} and now has $#{player[1].bank} total."
          else # player lost to dealer
            standard_loss (player)
          end
        end
      end
      puts
    end
  end
end
