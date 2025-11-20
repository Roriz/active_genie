# Extractor

The **Extractor** module analyzes unstructured text and extracts structured data using AI-powered analysis. It handles everything from simple data extraction to complex informal language patterns, making it perfect for processing user-generated content, product descriptions, social media posts, and conversational text.

Think of it as your **intelligent data parser** that can understand context, handle typos, interpret slang, and even detect rhetorical devices like sarcasm and understatement.

## Features

- **Structured data extraction** - Extract typed data from unstructured text using predefined JSON schemas
- **Informal text analysis** - Identifies and handles informal language patterns, including litotes, slang, and conversational expressions
- **Explanation tracking** - Provides reasoning for each extracted data point, improving transparency and debugging
- **Schema validation** - Supports complex validation rules including enums, ranges, and custom constraints
- **Multi-format support** - Works with social media posts, product listings, reviews, chat messages, and more

## Basic Usage

Extract structured data from text using predefined schemas:

```ruby
# Simple person extraction
text = "John Doe is 25 years old and works as a software engineer"
schema = {
  name: { type: 'string', description: 'Full name of the person' },
  age: { type: 'integer', description: 'Age in years' },
  profession: { type: 'string', description: 'Job title or profession' }
}

result = ActiveGenie::Extractor.call(text, schema)
result.data
# => {
#      name: "John Doe",
#      name_explanation: "Found directly at the beginning of text",
#      age: 25,
#      age_explanation: "Explicitly stated as 25 years old",
#      profession: "software engineer",
#      profession_explanation: "Identified as job title after 'works as'"
#    }
```

## Real-World Examples

### E-commerce Product Extraction

Perfect for parsing product listings from various sources:

```ruby
product = "Sony 65\" Class BRAVIA XR X95K 4K HDR Mini LED TV - $1999.99 (Save $500)"
schema = {
  brand: { type: 'string', description: 'Product brand' },
  display_size: { type: 'string', description: 'Screen size with units' },
  model: { type: 'string', description: 'Product model name' },
  display_type: { type: 'string', description: 'Type of display technology' },
  price: { type: 'number', minimum: 0, description: 'Current price' },
  discount: { type: 'number', minimum: 0, description: 'Discount amount if any' }
}

result = ActiveGenie::Extractor.with_explanation(product, schema)
result.data
# => {
#      brand: "Sony",
#      brand_explanation: "Brand name at the beginning",
#      display_size: "65\"",
#      display_size_explanation: "Size specification before 'Class'",
#      model: "BRAVIA XR X95K",
#      model_explanation: "Model name between Class and display type",
#      display_type: "4K HDR Mini LED TV",
#      display_type_explanation: "Complete display technology description",
#      price: 1999.99,
#      price_explanation: "Current price after dash in USD format",
#      discount: 500,
#      discount_explanation: "Savings amount in parentheses"
#    }
```

### Social Media Analysis

Extract insights from social media posts and interactions:

```ruby
post = "@alice liked @dave's photo and commented: 'Amazing sunset at the beach!'"
schema = {
  action: {
    type: 'string',
    enum: ["post", "comment", "like", "share", "retweet", "reply"],
    description: 'Primary social media action'
  },
  username: { type: 'string', description: 'Acting user' },
  target_user: { type: 'string', description: 'Target of the action' },
  content_type: { type: 'string', description: 'Type of content interacted with' },
  sentiment: {
    type: 'string',
    enum: ["positive", "negative", "neutral"],
    description: 'Overall sentiment of interaction'
  }
}

result = ActiveGenie::Extractor.call(post, schema)
result.data
# => {
#      action: "like",
#      action_explanation: "Primary action mentioned first",
#      username: "alice",
#      username_explanation: "User performing the action",
#      target_user: "dave",
#      target_user_explanation: "Owner of the content being liked",
#      content_type: "photo",
#      content_type_explanation: "Type specified as 'photo'",
#      sentiment: "positive",
#      sentiment_explanation: "Comment shows enthusiasm about sunset"
#    }
```

## Informal Text Processing

The **`with_litote`** method extends basic extraction by analyzing rhetorical devices and informal language patterns commonly found in conversational text. This is particularly valuable for processing user-generated content where people use indirect expressions, understatement, and informal speech patterns.

### Rhetorical Patterns Detected

- **Litotes** ("not bad", "isn't terrible") - Understatement using double negatives
- **Affirmative expressions** ("sure", "absolutely", "no problem") - Positive confirmations
- **Negative expressions** ("nah", "not really", "kind of meh") - Soft rejections
- **Sarcasm indicators** - Context-based sarcasm detection
- **Informal intensifiers** ("super", "totally", "kinda") - Casual emphasis

### Chat Message Analysis

Perfect for analyzing customer support chats, user feedback, and conversational interfaces:

```ruby
chat = "The new update isn't terrible, but it's not exactly amazing either"
schema = {
  sentiment: {
    type: 'string',
    enum: ['positive', 'negative', 'neutral', 'mixed'],
    description: 'Overall sentiment toward the update'
  },
  satisfaction_level: {
    type: 'integer',
    minimum: 1,
    maximum: 5,
    description: 'Satisfaction rating from 1-5'
  },
  feedback_type: {
    type: 'string',
    enum: ['compliment', 'complaint', 'suggestion', 'neutral_observation'],
    description: 'Type of feedback being provided'
  }
}

result = ActiveGenie::Extractor.with_litote(chat, schema)
result.data
# => {
#      sentiment: "mixed",
#      sentiment_explanation: "Uses litote 'isn't terrible' showing mild approval, balanced by 'not exactly amazing'",
#      satisfaction_level: 3,
#      satisfaction_level_explanation: "Lukewarm response indicates moderate satisfaction",
#      feedback_type: "neutral_observation",
#      feedback_type_explanation: "Balanced assessment without strong positive or negative bias",
#      message_litote: true,
#      litote_rephrased: "The new update is okay, but it could be better"
#    }
```

### Review Analysis

Extract meaningful insights from informal product reviews:

```ruby
review = "This restaurant isn't bad at all! The service wasn't horrible either."
schema = {
  overall_rating: {
    type: 'integer',
    minimum: 1,
    maximum: 5,
    description: 'Overall restaurant rating'
  },
  service_rating: {
    type: 'integer',
    minimum: 1,
    maximum: 5,
    description: 'Service quality rating'
  },
  recommendation: {
    type: 'boolean',
    description: 'Would recommend to others'
  }
}

result = ActiveGenie::Extractor.with_litote(review, schema)
result.data
# => {
#      overall_rating: 4,
#      overall_rating_explanation: "Positive sentiment via litote 'isn't bad at all'",
#      service_rating: 3,
#      service_rating_explanation: "Moderate positive via 'wasn't horrible'",
#      recommendation: true,
#      recommendation_explanation: "Overall positive tone suggests recommendation",
#      message_litote: true,
#      litote_rephrased: "This restaurant is quite good! The service was decent too."
#    }
```

### Performance Considerations

⚠️ **Processing Impact**: The `with_litote` method performs additional rhetorical analysis, which:
- Requires 2-3x more processing time than basic extraction
- May involve multiple AI model calls for complex text
- Best suited for conversational text under 500 words
- Consider background processing for high-volume applications

### When to Use Litote Processing

**✅ Ideal for:**
- Customer feedback and reviews
- Chat message analysis
- Social media sentiment analysis
- Survey responses with informal language
- User-generated content moderation

**❌ Not recommended for:**
- Formal documents or technical texts
- High-volume real-time processing
- Simple data extraction without sentiment needs
- Structured data like product catalogs

## Tips & Best Practices

- **Be descriptive with your schemas.** Include detailed descriptions for each field to help the AI understand what you're looking for. The more context you provide, the better the extraction quality.

- **Use validation constraints effectively.** Leverage `enum`, `minimum`, `maximum`, and other JSON schema constraints to guide extraction and ensure data quality.

- **Handle missing data gracefully.** Not all text will contain every field in your schema. The extractor will only return fields it can confidently identify.

- **Optimize schema complexity.** While the extractor can handle complex nested schemas, simpler schemas generally produce more reliable results and faster processing.

- **Choose the right method for your use case:**
  - Use `.call()` for straightforward data extraction from structured text
  - Use `.with_explanation()` when you need reasoning for debugging or transparency
  - Use `.with_litote()` for informal, conversational, or user-generated content

- **Test with real data.** Use representative samples of your actual text data when designing schemas, as real-world text often contains unexpected variations.

- **Consider context windows.** For very long texts, consider breaking them into smaller chunks as AI models have token limits that can affect extraction quality.

## Advanced Schema Patterns

### Multi-Type Fields

Handle fields that could have multiple valid types:

```ruby
# Product price that might be a number or "Contact for pricing"
schema = {
  price: {
    oneOf: [
      { type: 'number', minimum: 0 },
      { type: 'string', enum: ['Contact for pricing', 'Price on request', 'TBD'] }
    ]
  }
}
```

### Array Extraction

Extract lists and collections from text:

```ruby
text = "The product is available in red, blue, and green colors"
schema = {
  colors: {
    type: 'array',
    items: { type: 'string' },
    description: 'Available color options'
  }
}
# => { colors: ["red", "blue", "green"] }
```

### Conditional Fields

Create context-dependent extraction rules:

```ruby
review = "Great hotel! The pool was amazing and the spa was relaxing. Breakfast could be better."
schema = {
  rating: { type: 'integer', minimum: 1, maximum: 5 },
  amenities_mentioned: {
    type: 'array',
    items: {
      type: 'object',
      properties: {
        name: { type: 'string' },
        sentiment: { type: 'string', enum: ['positive', 'negative', 'neutral'] }
      }
    }
  }
}
```

## Interface

### `.call(text, data_to_extract, config = {})`

The primary extraction method that analyzes text and returns structured data based on your schema.

#### Parameters

| Name | Type | Description | Required | Example |
| --- | --- | --- | --- | --- |
| `text` | `String` | The text to analyze and extract data from | Yes | `"John Doe is 25 years old"` |
| `data_to_extract` | `Hash` | JSON schema defining the data structure to extract | Yes | `{ name: { type: 'string' } }` |
| `config` | `Hash` | Additional extraction configuration options | No | `{ model: "gpt-4", provider_name: "openai" }` |

#### Returns
`Hash` containing extracted values matching the schema structure, with explanation fields when using `with_explanation`.

#### Configuration Options
```ruby
config = {
  model: "gpt-4o",           # AI model to use
  provider_name: "openai",        # AI provider (openai, anthropic, google, deepseek)
  temperature: 0.1,          # Lower values for more consistent extraction
  max_tokens: 1000,          # Maximum response length
  timeout: 30                # Request timeout in seconds
}
```

### `.with_explanation(text, data_to_extract, config = {})`

Identical to `.call()` but includes detailed explanations for each extracted field. Use this method when you need transparency in the extraction process or for debugging purposes.

```ruby
# Returns ActiveGenie::Result with additional *_explanation fields in data
result = ActiveGenie::Extractor.with_explanation(text, schema)
result.data
# => {
#      name: "John Doe",
#      name_explanation: "Found directly at the beginning of the text",
#      age: 25,
#      age_explanation: "Explicitly stated as '25 years old'"
#    }
```

### `.with_litote(text, data_to_extract, config = {})`

Specialized extraction method that analyzes rhetorical devices and informal language patterns. Best for conversational text, reviews, and user-generated content.

#### Additional Returns
- `message_litote` - Boolean indicating if litotes were detected
- `litote_rephrased` - Positive rephrasing of the original text (when applicable)

```ruby
result = ActiveGenie::Extractor.with_litote("The weather isn't bad", schema)
result.data
# => {
#      mood: "positive",
#      mood_explanation: "Positive sentiment expressed through litote",
#      message_litote: true,
#      litote_rephrased: "The weather is good"
#    }
```

---

## Response Structure

All extractor methods return an `ActiveGenie::Result` instance with:

```ruby
result = ActiveGenie::Extractor.call(text, schema)

# Access extracted data
result.data
# => {
#      field_name: extracted_value,
#      # With explanation/litote methods:
#      field_name_explanation: "Reasoning for extraction",
#      # Litote-specific fields (with_litote only):
#      message_litote: true/false,
#      litote_rephrased: "Positive rephrasing of original text"
#    }

# Access reasoning about the extraction process
result.reasoning
# => "Explanation of extraction methodology and approach"

# Convert to different formats
result.to_h    # => { data: {...}, reasoning: "...", metadata: {...} }
result.to_json # => JSON string
```

### Error Handling

The extractor gracefully handles various error conditions:

- **Missing fields**: Fields not found in text are omitted from results
- **Type mismatches**: Invalid data types are either converted or omitted
- **API failures**: Network issues return partial results when possible
- **Schema validation**: Invalid schemas raise descriptive errors

```ruby
begin
  result = ActiveGenie::Extractor.call(text, schema)
  data = result.data
rescue ActiveGenie::InvalidProviderError => e
  # Handle provider configuration issues
rescue ActiveGenie::ExtractionError => e
  # Handle extraction-specific errors
end
```

⚠️ **Performance Considerations**

- **Basic extraction** (`.call`): ~1-3 seconds for typical text
- **With explanations**: ~2-5 seconds due to additional reasoning
- **Litote processing**: ~3-8 seconds for rhetorical analysis
- **Batch processing**: Consider background jobs for high-volume extraction
- **Token limits**: Large texts may be truncated; consider chunking for optimal results
