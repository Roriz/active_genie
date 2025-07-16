# Factory

The **Factory** module generates a list of items based on a given theme, inspired by the game "Family Feud." It impersonates a survey of average people's opinions and generates an ordered, survey-style answer list. The goal is to determine the most common answers for a given topic, with the most likely answers appearing first.

## Basic Usage

Generate a list of items for a given theme:

```ruby
theme = "Industries that are most likely to be affected by climate change"
result = ActiveGenie::Factory.feud(theme)
# => [
#      "Agriculture",
#      "Insurance",
#      "Tourism",
#      "Fishing",
#      "Real Estate"
#    ]
```

## Tips

  - **Be specific with your theme.** A clear and concise theme will produce better, more relevant results.
  - **Think like a survey.** The module is designed to mimic popular opinion, so frame your themes as questions you might ask a group of people.
  - **Order matters.** The returned list is ordered by popular consensus, from most to least common.

## Interface

### .feud(theme, config: {})

  - `theme` [String] - The topic or question for the survey.
  - `config` [Hash] - Additional configuration that modifies the generation behavior. The most relevant option is `number_of_items` to control the size of the list.

**Returns an `Array` of strings containing:**

  - A numbered list of items representing the most common answers for the given theme.
