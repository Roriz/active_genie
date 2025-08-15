# Ranker

The **Ranker** module organizes and ranks multiple players based on their content quality through a sophisticated multi-stage evaluation process. It combines scoring, elimination, ELO rating, and head-to-head comparisons to produce fair and accurate rankings.

The ranking system is designed to handle any number of players, from small groups to large tournaments, automatically adapting its methodology based on the size and quality distribution of the player pool.

## Overview

The ranking system performs the following steps:

1. **Initial Scoring**: Each player's textual content is evaluated using `ActiveGenie::Scorer`. This produces a `score` based on multiple expert reviews, establishing baseline quality metrics.

2. **Elimination of Poor Performers**: Players whose scores show a high coefficient of variation (indicating inconsistency) are progressively eliminated. This ensures that only competitive candidates continue in the ranking process.

3. **ELO Ranking**: If there are more than 10 eligible players, an ELO-based ranking is applied. Battles between players are simulated via `ActiveGenie::Comparator`, and scores are updated using an ELO algorithm tailored to the ranking context.

4. **Free-for-All Matches**: Finally, the remaining players engage in head-to-head matches where each unique pair competes. Match outcomes (wins, losses, draws) are recorded to finalize the rankings.

## Basic Usage

Rank a collection of players based on specific criteria:

```ruby
players = [
  "Implementation uses dependency injection for better testability",
  "Code has comprehensive documentation and clear naming conventions", 
  "Uses modern design patterns with proper separation of concerns",
  "Legacy code with tightly coupled components but working functionality"
]

criteria = "Evaluate code quality, maintainability, and software engineering best practices"

result = ActiveGenie::Ranker.call(players, criteria)
# => {
#      players: [
#        { content: "Uses modern design patterns...", score: 85, elo: 1245, rank: 1, eliminated: nil },
#        { content: "Implementation uses dependency injection...", score: 82, elo: 1198, rank: 2, eliminated: nil },
#        { content: "Code has comprehensive documentation...", score: 78, elo: 1156, rank: 3, eliminated: nil },
#        { content: "Legacy code with tightly coupled...", score: 45, elo: 892, rank: 4, eliminated: nil }
#      ],
#      statistics: {
#        total_players: 4,
#        eliminated_players: 0,
#        elo_rounds: 1,
#        ffa_matches: 6
#      }
#    }
```

## Advanced Usage Examples

### Ranking Product Descriptions

```ruby
products = [
  "iPhone 15 Pro Max with A17 Pro chip, titanium design, and advanced camera system",
  "Samsung Galaxy S24 Ultra with S Pen, 200MP camera, and AI-powered features",
  "Google Pixel 8 Pro with computational photography and pure Android experience",
  "OnePlus 12 with fast charging, flagship performance, and OxygenOS"
]

criteria = "Best smartphone for photography enthusiasts who value camera quality, image processing, and creative features"

result = ActiveGenie::Ranker.call(products, criteria, config: { 
  ranker: { score_variation_threshold: 25 },
  providers: { openai: { model: "gpt-4" } }
})
```

### Ranking Code Solutions

```ruby
solutions = [
  { name: "Solution A", content: "Uses recursion with memoization for dynamic programming approach" },
  { name: "Solution B", content: "Iterative solution with O(1) space complexity using two variables" },
  { name: "Solution C", content: "Brute force approach with nested loops, easy to understand" },
  { name: "Solution D", content: "Functional programming approach using reduce and immutable data" }
]

criteria = "Evaluate algorithmic efficiency, code readability, and maintainability for a fibonacci sequence implementation"

result = ActiveGenie::Ranker.call(solutions, criteria)
```

## Components

- **Tournament**: The main orchestrator that combines all ranking methodologies. Handles the complete multi-stage process from initial scoring through final rankings.

- **Scoring**: Evaluates each player's content using AI-powered scoring with multiple expert reviewers to establish baseline quality metrics.

- **ELO Ranking**: Applies an ELO-based system to rank players through simulated head-to-head battles. Updates players' ELO scores based on match outcomes with penalties for losses and bonuses for wins.

- **Free-for-All**: Conducts comprehensive pairwise matches among eligible players to record detailed win/loss/draw statistics and refine the final standings.

## Usage

### Basic Ranking

Call the ranker using:

```ruby
result = ActiveGenie::Ranker.call(players, criteria, config: {})
```

### Tournament Mode

For tournament-style ranking with full multi-stage evaluation:

```ruby
result = ActiveGenie::Ranker.by_tournament(players, criteria, config: {})
```

### ELO-Only Ranking

For pure ELO-based ranking without initial scoring:

```ruby
result = ActiveGenie::Ranker.by_elo(players, criteria, config: {})
```

### Free-for-All Ranking

For head-to-head matches without ELO progression:

```ruby
result = ActiveGenie::Ranker.by_free_for_all(players, criteria, config: {})
```

### Score-Only Ranking

For simple scoring without competitive matches:

```ruby
result = ActiveGenie::Ranker.by_scoring(players, criteria, config: {})
```

- `players`: A collection of player instances (strings, hashes, or objects), each containing textual content to be evaluated.
- `criteria`: A string defining the evaluation criteria used by the scoring and comparison systems.
- `config`: A hash of additional parameters for customization (e.g., model, api_key, thresholds).
## Interface

### .call(players, criteria, config: {})

The primary entry point that automatically selects the best ranking methodology based on the number of players and their characteristics.

- `players` [Array<String, Hash, Object>] - Collection of player content to rank. Can be simple strings or complex objects with metadata.
- `criteria` [String] - The evaluation criteria that defines what makes one player better than another.
- `config` [Hash] - Additional configuration for customizing the ranking behavior.

**Returns a Hash containing:**

- `players` [Array<Hash>] - Ranked list of players with their scores, ELO ratings, and statistics.
- `statistics` [Hash] - Summary information about the ranking process (total players, eliminations, rounds, etc.).

### .by_tournament(players, criteria, config: {})

Full multi-stage tournament ranking with scoring, elimination, ELO battles, and free-for-all matches.

### .by_elo(players, criteria, config: {})

Pure ELO-based ranking through head-to-head battles. Best for competitive scenarios where relative performance matters more than absolute scores.

### .by_free_for_all(players, criteria, config: {})

Complete round-robin tournament where every player faces every other player exactly once.

### .by_scoring(players, criteria, config: {})

Simple scoring-based ranking using AI evaluation without competitive matches.

-----

### Player Response Structure

Each player in the results contains:

- `content` [String] - The original player content that was evaluated.
- `name` [String] - Player identifier (auto-generated from content if not provided).
- `score` [Integer] - Quality score from 0-100 based on AI evaluation.
- `elo` [Integer] - ELO rating reflecting competitive performance.
- `rank` [Integer] - Final position in the rankings (1 = best).
- `eliminated` [String|nil] - Reason for elimination if applicable.
- `ffa_wins` [Integer] - Number of free-for-all victories.
- `ffa_losses` [Integer] - Number of free-for-all defeats.
- `ffa_draws` [Integer] - Number of free-for-all draws.

### Statistics Structure

The statistics object provides:

- `total_players` [Integer] - Initial number of players in the ranking.
- `eliminated_players` [Integer] - Number of players eliminated during the process.
- `elo_rounds` [Integer] - Number of ELO ranking rounds conducted.
- `ffa_matches` [Integer] - Total number of free-for-all matches played.
- `coefficient_of_variation` [Float] - Measure of score consistency among players.

## Tips

- **Be specific about player content.** The more descriptive and detailed each player's content, the better the AI can evaluate and compare them. Include relevant characteristics that relate to your criteria.

- **Write clear, focused criteria.** Specify exactly what you're looking for. Instead of "best code," use "most maintainable code with clear documentation and proper error handling."

- **Consider player count.** Small groups (≤10 players) will use simpler ranking methods, while larger groups benefit from the full tournament system with multiple elimination rounds.

- **Use structured player data when possible.** Instead of plain strings, provide hashes with additional metadata like names, categories, or pre-computed attributes.

- **Monitor coefficient of variation.** High variation (>30) indicates inconsistent quality among players and may trigger more aggressive elimination rounds.

- **Experiment with different ranking methods.** Try `by_elo` for competitive scenarios, `by_scoring` for quality-focused rankings, or `by_free_for_all` for comprehensive head-to-head analysis.

The method processes the players through scoring, elimination, and ranking phases, then returns a hash containing the player statistics and rankings.

## Practical Examples

### Example 1: Restaurant Menu Items

```ruby
menu_items = [
  "Grilled salmon with lemon herb butter, served with roasted vegetables and quinoa",
  "Classic cheeseburger with lettuce, tomato, pickles on brioche bun with fries", 
  "Vegan Buddha bowl with chickpeas, avocado, kale, and tahini dressing",
  "Chicken tikka masala with basmati rice and naan bread"
]

criteria = "Most appealing to health-conscious diners who value nutritional balance and fresh ingredients"

result = ActiveGenie::Ranker.call(menu_items, criteria)
# Will likely rank the Buddha bowl and salmon highly due to health focus
```

### Example 2: Job Candidate Evaluations

```ruby
candidates = [
  {
    name: "Alice Johnson",
    content: "5 years React experience, led 3 major projects, strong in TypeScript and testing"
  },
  {
    name: "Bob Smith", 
    content: "10 years full-stack experience, knows multiple languages, good communication skills"
  },
  {
    name: "Carol Davis",
    content: "Recent bootcamp graduate, enthusiastic learner, built several personal projects"
  }
]

criteria = "Best fit for senior frontend developer role requiring React expertise and team leadership"

result = ActiveGenie::Ranker.by_tournament(candidates, criteria)
```

### Example 3: Marketing Campaign Variations

```ruby
campaigns = [
  "Save 20% on all items this weekend only - Limited time offer!",
  "Discover premium quality at everyday prices - Shop our collection", 
  "Join thousands of happy customers - Experience the difference today",
  "Free shipping on orders over $50 - No minimum purchase required"
]

criteria = "Most likely to drive immediate conversions for an e-commerce fashion brand targeting millennials"

# Use ELO-only ranking for competitive comparison
result = ActiveGenie::Ranker.by_elo(campaigns, criteria, config: {
  providers: { openai: { model: "gpt-4" } }
})
```

### Example 4: Content Strategy Analysis

```ruby
content_pieces = [
  { 
    type: "blog_post",
    content: "How to optimize your LinkedIn profile for better job opportunities - comprehensive guide with examples"
  },
  {
    type: "video_script", 
    content: "5-minute tutorial showing step-by-step LinkedIn optimization with screen recording"
  },
  {
    type: "infographic",
    content: "Visual checklist of 10 essential LinkedIn profile elements with before/after examples"
  },
  {
    type: "podcast_episode",
    content: "Interview with hiring manager discussing what they look for in LinkedIn profiles"
  }
]

criteria = "Most effective content format for engaging career-focused audience and driving profile views"

result = ActiveGenie::Ranker.by_free_for_all(content_pieces, criteria)
```

## Possible improvements
- Adjust initial criteria to ensure consistency
- Adjust each player's content to ensure consistency  
- Support players with images or audio
- Parallelize processing battles and scoring

## Ranking Configuration

Configure the ranking behavior through the config hash:

| Config | Description | Default | Example |
|--------|-------------|---------|---------|
| `score_variation_threshold` | Threshold for eliminating players with inconsistent scores (higher = more lenient) | `30` | `25` for stricter elimination |
| `elo_k_factor` | ELO rating change sensitivity (higher = more volatile ratings) | `32` | `16` for stable rankings |
| `elo_rounds_limit` | Maximum number of ELO rounds before moving to free-for-all | `10` | `5` for faster processing |
| `min_players_for_elo` | Minimum players required to trigger ELO ranking | `10` | `15` for larger tournaments |

### Provider Configuration

| Config | Description | Default |
|--------|-------------|---------|
| `providers.openai.model` | OpenAI model for evaluations | `"gpt-4o"` |
| `providers.anthropic.model` | Anthropic model for evaluations | `"claude-3-sonnet-20240229"` |
| `providers.openai.api_key` | OpenAI API key | `ENV['OPENAI_API_KEY']` |

Example configuration:

```ruby
config = {
  ranker: {
    score_variation_threshold: 25,
    elo_k_factor: 24,
    min_players_for_elo: 12
  },
  providers: {
    openai: {
      model: "gpt-4",
      api_key: "your-api-key"
    }
  },
  log: {
    level: :debug
  }
}

result = ActiveGenie::Ranker.call(players, criteria, config: config)
```
