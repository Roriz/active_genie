# Battle
AI-powered battle evaluation system that determines winners between two players based on specified criteria.

## Features
- Content comparison - Evaluate submissions from two players against defined criteria
- Objective analysis - AI-powered assessment of how well each player meets requirements
- Detailed reasoning - Comprehensive explanation of why a winner was chosen
- Draw avoidance - Suggestions on how to modify content to avoid draws
- Flexible input - Support for both string content and structured data with content field

## Basic Usage
Evaluate a battle between two players with simple text content:

```ruby
player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Battle.call(player_a, player_b, criteria)
# => {
#      winner_player: "Implementation uses dependency injection for better testability",
#      reasoning: "Player A's implementation demonstrates better maintainability through dependency injection,
#                 which allows for easier testing and component replacement. While Player B has good test coverage,
#                 the tight coupling makes the code harder to maintain and modify.",
#      what_could_be_changed_to_avoid_draw: "Focus on specific architectural patterns and design principles"
#    }
```

## Interface
### .call(player_a, player_b, criteria, config: {})
- `player_a` [String, Hash] - The content or submission from the first player
- `player_b` [String, Hash] - The content or submission from the second player
- `criteria` [String] - The evaluation criteria or rules to assess against
- `config` [Hash] - Additional configuration config that modify the battle evaluation behavior

Returns a Hash containing:
- `winner_player` [String, Hash] - The winning player's content (either player_a or player_b)
- `reasoning` [String] - Detailed explanation of why the winner was chosen
- `what_could_be_changed_to_avoid_draw` [String] - A suggestion on how to avoid a draw
