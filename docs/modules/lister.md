# Lister

The **Lister** module generates a list of items based on a given theme, inspired by the game "Family Feud." It impersonates a survey of average people's opinions and generates an ordered, survey-style answer list. The goal is to determine the most common answers for a given topic, with the most likely answers appearing first.

The module uses AI to reason about what answers would be mentioned most frequently if a group of average people were surveyed on the given theme, ensuring the results reflect general public opinion and cultural impact.

## Basic Usage

Generate a list of items for a given theme:

```ruby
theme = "Industries that are most likely to be affected by climate change"
result = ActiveGenie::Lister.call(theme)
result.data
# => [
#      "Agriculture",
#      "Insurance", 
#      "Tourism",
#      "Fishing",
#      "Real Estate"
#    ]

result.reasoning
# => "List generated using Family Feud style survey simulation reflecting general public opinion"

result.metadata
# => { provider: :openai, model: "gpt-4o-mini", tokens: {...}, list_size: 5 }
```

Generate a list with custom configuration:

```ruby
theme = "Most popular breakfast foods"
result = ActiveGenie::Lister.call(theme, config: { number_of_items: 8 })
result.data
# => [
#      "Eggs",
#      "Toast", 
#      "Cereal",
#      "Pancakes",
#      "Bacon",
#      "Coffee",
#      "Orange Juice",
#      "Oatmeal"
#    ]
```

## Advanced Usage

### Different Methodologies

The Lister module provides different approaches for generating lists based on your specific needs:

#### Feud (Default)
The default "Family Feud" style survey simulation, perfect for general public opinion topics:

```ruby
theme = "Things people do when they're bored"
result = ActiveGenie::Lister.with_feud(theme)
result.data
# => [
#      "Watch TV",
#      "Browse social media",
#      "Listen to music", 
#      "Read a book",
#      "Take a nap"
#    ]
```

#### Juries
Generates a list of expert jury roles suitable for evaluating specific content:

```ruby
text = "A technical proposal for implementing microservices architecture"
criteria = "Evaluate technical feasibility and business impact"
result = ActiveGenie::Lister.with_juries(text, criteria)
result.data
# => [
#      "Software Architect",
#      "DevOps Engineer",
#      "Business Analyst"
#    ]
```

## Real-World Examples

### Market Research
```ruby
theme = "Factors consumers consider when buying a smartphone"
result = ActiveGenie::Lister.call(theme)
result.data
# => [
#      "Price",
#      "Battery life",
#      "Camera quality",
#      "Storage capacity",
#      "Brand reputation"
#    ]
```

### Content Planning
```ruby
theme = "Topics people want to learn about in online courses"
result = ActiveGenie::Lister.call(theme, config: { number_of_items: 10 })
result.data
# => [
#      "Programming",
#      "Digital Marketing",
#      "Data Analysis",
#      "Graphic Design",
#      "Photography",
#      "Language Learning",
#      "Personal Finance",
#      "Cooking",
#      "Fitness",
#      "Public Speaking"
#    ]
```

### Problem-Solving
```ruby
theme = "Common challenges faced by remote workers"
result = ActiveGenie::Lister.call(theme)
result.data
# => [
#      "Communication issues",
#      "Work-life balance",
#      "Isolation and loneliness",
#      "Technical difficulties",
#      "Time management"
#    ]
```

## Tips

  - **Be specific with your theme.** A clear and concise theme will produce better, more relevant results. Instead of "food," try "comfort foods people crave during winter."
  - **Think like a survey.** The module is designed to mimic popular opinion, so frame your themes as questions you might ask a group of people in a mall or on the street.
  - **Order matters.** The returned list is ordered by popular consensus, from most to least common. The first items should represent what most people would immediately think of.
  - **Consider cultural context.** The results reflect general cultural awareness and popular opinions, making them ideal for market research, content creation, and understanding public perception.
  - **Use descriptive themes.** Instead of "cars," try "car features that are most important to families" or "reasons people choose electric vehicles."
  - **Avoid overly technical topics.** The feud methodology works best with themes that average people can relate to and have opinions about.

## Interface

### .call(theme, config: {})

The primary interface that uses the Feud methodology by default.

  - `theme` [String] - The topic or question for the survey. Should be framed as something you'd ask in a public survey.
  - `config` [Hash] - Additional configuration that modifies the generation behavior. The most relevant option is `number_of_items` to control the size of the list.

**Returns `ActiveGenie::Result` instance containing:**

```ruby
result = ActiveGenie::Lister.call(theme)

# Access the list
result.data
# => ["Item 1", "Item 2", "Item 3", ...]

# Access reasoning
result.reasoning
# => "List generated using Family Feud style survey simulation"

# Access metadata
result.metadata
# => {
#      provider: :openai,
#      model: "gpt-4o-mini",
#      tokens: {...},
#      list_size: 5,
#      methodology: "feud"
#    }
```

-----

### .with_feud(theme, config: {})

Explicitly uses the "Family Feud" survey methodology. Returns `ActiveGenie::Result` with the same structure as `.call()`.

  - `theme` [String] - The topic or question for the survey.
  - `config` [Hash] - Additional configuration that modifies the generation behavior.

-----

### .with_juries(text, criteria, config: {})

Generates a list of expert jury roles suitable for evaluating specific content against given criteria. Returns `ActiveGenie::Result`.

  - `text` [String] - The content that needs to be evaluated by experts.
  - `criteria` [String] - The evaluation criteria that will guide jury selection.
  - `config` [Hash] - Additional configuration that modifies the recommendation process.

  - A list of expert roles or jury types best suited to evaluate the given content and criteria.
