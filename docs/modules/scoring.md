# Scoring
Text evaluation system that provides detailed scoring and feedback using multiple expert reviewers.

## Features
- Multi-reviewer evaluation - Get scores and feedback from multiple AI-powered expert reviewers
- Automatic reviewer selection - Smart recommendation of reviewers based on content and criteria
- Detailed feedback - Comprehensive reasoning for each reviewer's score
- Customizable weights - Adjust the importance of different reviewers' scores
- Flexible criteria - Score text against any specified evaluation criteria

## Basic Usage

Score text using predefined reviewers:

```ruby
text = "The code implements a binary search algorithm with O(log n) complexity"
criteria = "Evaluate technical accuracy and clarity"
reviewers = ["Algorithm Expert", "Technical Writer"]

result = ActiveGenie::Scoring.call(text, criteria, reviewers)
# => {
#      algorithm_expert_score: 95,
#      algorithm_expert_reasoning: "Accurately describes binary search and its complexity",
#      technical_writer_score: 90,
#      technical_writer_reasoning: "Clear and concise explanation of the algorithm",
#      final_score: 92.5
#    }
```

## Automatic Reviewer Selection

When no reviewers are specified, the system automatically recommends appropriate reviewers:

```ruby
text = "The patient shows signs of improved cardiac function"
criteria = "Evaluate medical accuracy and clarity"

result = ActiveGenie::Scoring.call(text, criteria)
# => {
#      cardiologist_score: 88,
#      cardiologist_reasoning: "Accurate assessment of cardiac improvement",
#      medical_writer_score: 85,
#      medical_writer_reasoning: "Clear communication of medical findings",
#      general_practitioner_score: 90,
#      general_practitioner_reasoning: "Well-structured medical observation",
#      final_score: 87.7
#    }
```

## Interface

### `.call(text, criteria, reviewers = [], config: {})`
Main interface for scoring text content.

#### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | String | The text content to analyze |
| `criteria` | String | The evaluation criteria |
| `reviewers` | Array of String | Optional list of reviewer roles |
| `config` | Hash | Additional configuration options |

### `RecommendedReviewers.call(text, criteria, config: {})`
Recommends appropriate reviewers based on content and criteria.

#### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | String | The text content to analyze |
| `criteria` | String | The evaluation criteria |
| `config` | Hash | Additional configuration options |

### Usage Notes
- Best suited for objective evaluation of text content
- Provides balanced scoring through multiple reviewers
- Automatically handles reviewer selection when needed
- Supports custom weighting of reviewer scores
- Returns detailed reasoning for each score

Performance Impact: Using multiple reviewers or requesting detailed feedback may increase processing time.
