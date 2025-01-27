# player_a = 'square'
# player_b = 'circle'
# criteria = 'items that look rounded'
# result = ActiveGenie::EloRanking.call(player_a, player_b, criteria)
# puts result # => { winner_player: "circle", reasoning: "items that look rounded is a good criteria to judge a square and a circle" }


module ActiveGenie
  # Battle module
  module Battle
    module_function

    def basic(*args)
      Basic.call(*args)
    end
  end
end
