# Comparator

The **Comparator** module conducts a verbal debate between two players, where each presents their strengths and how they meet the given criteria. The goal of a comparator is to determine a winner.

The debate has a structure similar to a political debate:

  - Player A presents its strengths and how it meets the criteria.
  - Player B presents its strengths and how it meets the criteria.
  - Player A presents its counter-arguments.
  - Player B presents its counter-arguments.
  - Player A presents its final arguments.
  - Player B presents its final arguments.
  - An impartial judge determines the winner.

**Note:** This structure can be changed to better fit the latest prompt engineering techniques.

## Basic Usage

Evaluate a comparator between two players with simple text content:

```ruby
player_a = "Implementation uses dependency injection for better testability"
player_b = "Code has high test coverage but tightly coupled components"
criteria = "Evaluate code quality and maintainability"

result = ActiveGenie::Comparator.call(player_a, player_b, criteria)
result.data
# => {
#      winner: "Implementation uses dependency injection for better testability",
#      loser: "Code has high test coverage but tightly coupled components",
#      reasoning: "Player A's implementation demonstrates better maintainability through dependency injection,
#                  which allows for easier testing and component replacement. While Player B has good test coverage,
#                  the tight coupling makes the code harder to maintain and modify."
#    }

result.metadata
# => {
#      provider: :openai,
#      model: "gpt-4o-mini",
#      tokens: {...},
#      debate_rounds: 3
#    }
```

## Tips

  - **The more descriptive you are about each player, the better.** However, avoid mentioning too many other characters, as this can confuse the LLM.
  - **Describe characteristics that directly influence the criteria.** For example, if you're comparing two cellphones based on style, be descriptive about their design, colors, and materials.
  - **Avoid depending on the raw output**, as it can change drastically without notice. However, feel free to use it for debugging. For example, try changing the criteria to see how the output is affected.
  - **Be descriptive with the criteria.** What are the most important characteristics? Will the comparator take place in a specific location? Are there any restrictions, such as needing a cellphone that fits in one hand or can be used in the rain?

## Interface

### .call(player_a, player_b, criteria, config: {})

  - `player_a` [String, Hash] - The content or submission from the first player.
  - `player_b` [String, Hash] - The content or submission from the second player.
  - `criteria` [String] - The evaluation criteria or rules to assess against.
  - `config` [Hash] - Additional configuration that modifies the comparator evaluation behavior.

**Returns `ActiveGenie::Result` instance containing:**

```ruby
result = ActiveGenie::Comparator.call(player_a, player_b, criteria)

# Access comparison results
result.data
# => {
#      winner: "...",   # The winning player's content
#      loser: "...",    # The losing player's content
#      reasoning: "..." # Explanation of why the winner was chosen
#    }

# Access overall reasoning
result.reasoning
# => "Debate methodology and decision process explanation"

# Access metadata
result.metadata
# => {
#      provider: :openai,
#      model: "gpt-4o-mini",
#      tokens: {...},
#      debate_rounds: 3,
#      duration_ms: 2500
#    }
```

-----

### Fight

The **Fight** module is a specialized version of `debate` designed for combat scenarios between two fighters, such as martial artists, heroes, or other characters. The evaluation process simulates a fight using words, techniques, strategies, and reasoning.

As a submodule of `Comparator`, the goal of a fight is to determine the winner, there is no draw. The input and output are the same as `Comparator`, but the evaluation process is different.

The basic structure of a fight is:

  - Player A makes a self-presentation and introduces its fighter.
  - Player B makes a self-presentation and introduces its fighter.
  - Player A takes the first turn.
  - Player B takes the first turn.
  - Player A takes the second turn.
  - Player B takes the second turn.
  - Player A takes the third turn.
  - Player B takes the third turn.
  - Player A takes the final turn.
  - Player B takes the final turn.
  - An impartial judge determines the winner.

**Note:** The number of turns and the details of each turn can change without notice.

#### Example Output

> **Master Crane:** My Crane Kung Fu relies on lightness and precision, striking where your heavy blows simply can't reach. Your Ox Bull Charge is powerful, but too direct; I'd dance aside and tap your pressure points before you could even turn.
>
> **Iron Ox:** While speed is impressive, strength dominates in a real fight. My Ox Bull Charge would absorb your nimble attacks, and my sheer mass would pin you before you could even flutter away\!
>
> **Master Crane:** Adaptability ensures survival. As you lumber forward, I would use your momentum to redirect you. Your own strength becomes your undoing as you stumble into my calculated traps.


```ruby
player_a = "Master Crane, a graceful fighter whose Crane Kung Fu relies on lightness, precision, and redirecting an opponent's momentum."
player_b = "Iron Ox, a powerful brawler whose Ox Bull Charge style uses immense strength and mass to overwhelm opponents."
criteria = "Determine the winner of the fight based on skill, strategy, and adaptability in a one-on-one duel."

result = ActiveGenie::Comparator.by_fight(player_a, player_b, criteria)
result.data
# => {
#      winner: "Master Crane, a graceful fighter...",
#      loser: "Iron Ox, a powerful brawler...",
#      reasoning: "Master Crane's Crane Kung Fu relies on lightness and precision, striking where Iron Ox's Ox Bull Charge is powerful but too direct..."
#    }

result.metadata
# => {
#      provider: :openai,
#      model: "gpt-4o-mini",
#      tokens: {...},
#      fight_rounds: 10
#    }
```

## Tips

  - **Describe each fighter's movements as vividly as possible.** For example: What are their top five movements? How destructive or fast is each movement? Does any movement have a drawback?
  - To help measure the movements, you could create an analysis. For instance, if this fighter were a **Magic: The Gathering** card, what would be the cost or rarity of each movement? Is a movement common, epic, or legendary?
  - **Be descriptive with the criteria.** Will they fight on specific terrain? Are any weapons disallowed? Are there any hard elimination rules, like a timer or a penalty for touching the floor?
