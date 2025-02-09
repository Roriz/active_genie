# league

The `ActiveGenie::League` module organizes players based on scores derived from textual evaluations and then ranks them using a multi-stage process. It leverages the scoring system from the `ActiveGenie::Scoring` module to assign initial scores, and then applies advanced ranking methods to produce a competitive league.

## Overview

The league system performs the following steps:

1. **Initial Scoring**: Each player’s textual content is evaluated using `ActiveGenie::Scoring`. This produces a `score` based on multiple expert reviews.

2. **Elimination of Poor Performers**: Players whose scores show a high coefficient of variation (indicating inconsistency) are progressively eliminated. This ensures that only competitive candidates continue in the ranking process.

3. **ELO Ranking**: If there are more than 10 eligible players, an ELO-based ranking is applied. Battles between players are simulated via `ActiveGenie::Battle`, and scores are updated using an ELO algorithm tailored to the league.

4. **Free for all Matches**: Finally, the remaining players engage in head-to-head matches where each unique pair competes. Match outcomes (wins, losses, draws) are recorded to finalize the rankings.

## Components

- **league**: Orchestrates the entire ranking process. Initializes player scores, eliminates outliers, and coordinates ranking rounds.

- **EloRanking**: Applies an ELO-based system to rank players through simulated battles. It updates players’ ELO scores based on match outcomes and predefined rules (including penalties for losses).

- **Free for all**: Conducts complete pairwise matches among eligible players to record win/loss/draw statistics and refine the final standings.

## Usage

Call the league using:

```ruby
result = ActiveGenie::League::league.call(players, criteria, options: {})
```

- `players`: A collection of player instances, each containing textual content to be scored.
- `criteria`: A string defining the evaluation criteria used by the scoring system.
- `options`: A hash of additional parameters for customization (e.g., model, api_key).

The method processes the players through scoring, elimination, and ranking phases, then returns a hash containing the player statistics and rankings.

## Possible improvements
- Adjust initial criteria to ensure consistency
- Adjust each player's content to ensure consistency
- Support players with images or audio
- Parallelize processing battles and scoring