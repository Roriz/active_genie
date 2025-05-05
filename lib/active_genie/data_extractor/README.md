# Data Extractor
Extract structured data from text using AI-powered analysis, handling informal language and complex expressions.

## ✨ Features
- Structured data extraction - Extract typed data from unstructured text using predefined schemas
- Informal text analysis - Identifies and handles informal language patterns, including litotes
- Explanation tracking - Provides reasoning for each extracted data point

## Basic Usage

Extract structured data from text using predefined schemas:

```ruby
text = "John Doe is 25 years old"
schema = {
  name: { type: 'string', description: 'Full name of the person' },
  age: { type: 'integer', description: 'Age in years' }
}
result = ActiveGenie::DataExtractor.call(text, schema)
# => {
#      name: "John Doe",
#      name_explanation: "Found directly in text",
#      age: 25,
#      age_explanation: "Explicitly stated as 25 years old"
#    }

product = "Nike Air Max 90 - Size 42 - $199.99"
schema = {
  brand: {
    type: 'string',
    enum: ["Nike", "Adidas", "Puma"]
  },
  price: {
    type: 'number',
    minimum: 0
  },
  currency: {
    type: 'string',
    enum: ["USD", "EUR"]
  },
  size: {
    type: 'integer',
    minimum: 35,
    maximum: 46
  }
}

result = ActiveGenie::DataExtractor.call(product, schema)
# => {
#      brand: "Nike",
#      brand_explanation: "Brand name found at start of text",
#      price: 199.99,
#      price_explanation: "Price found in USD format at end",
#      size: 42,
#      size_explanation: "Size explicitly stated in the middle",
#      currency: "USD",
#      currency_explanation: "Derived from $ symbol"
#    }
```

## Informal Text Processing

The `from_informal` method extends the basic extraction by analyzing rhetorical devices and informal language patterns like:

- Litotes ("not bad", "isn't terrible")
- Affirmative expressions ("sure", "no problem")
- Negative expressions ("nah", "not really")

### Example

```ruby
text = "The weather isn't bad today"
schema = {
  mood: { type: 'string', description: 'The mood of the message' }
}

result = ActiveGenie::DataExtractor.from_informal(text, schema)
# => {
#      mood: "positive",
#      mood_explanation: "Speaker views weather favorably",
#      message_litote: true,
#      litote_rephrased: "The weather is good today"
#    }
```

### Usage Notes
- Best suited for processing conversational user inputs
- Automatically detects and interprets litotes
- Provides rephrased positive statements for litotes
- May require more processing time due to rhetorical analysis
- Accuracy depends on context clarity

⚠️ Performance Impact: This method performs additional rhetorical analysis, which can increase processing time.

## Interface

### `.call(text, data_to_extract, config = {})`
Extracts structured data from text based on a predefined schema.

#### Parameters
| Name | Type | Description | Required | Example |
| --- | --- | --- | --- | --- |
| `text` | `String` | The text to analyze and extract data from | Yes | "John Doe is 25 years old" |
| `data_to_extract` | `Hash` | Schema defining the data structure to extract | Yes | `{ name: { type: 'string' } }` |
| `config` | `Hash` | Additional extraction configuration | No | `{ model: "gpt-4" }` |

#### config
| Name | Type | Description |
| --- | --- | --- |
| `model` | `String` | The model to use for the extraction |
| `api_key` | `String` | The API key to use for the extraction |

#### Returns
`Hash` containing:
- Extracted values matching the schema structure
- Explanation field for each extracted value
- Additional analysis fields when using `from_informal`

### `.from_informal(text, data_to_extract, config = {})`
Extends  extraction with rhetorical analysis, particularly for litotes.

#### Additional Return Fields
| Name | Type | Description |
| --- | --- | --- |
| `message_litote` | `Boolean` | Whether the text contains a litote |
| `litote_rephrased` | `String` | Positive rephrasing of any detected litote |

⚠️ Performance Considerations
- Both methods may require multiple AI model calls
- Informal processing requires additional rhetorical analysis
- Consider background processing for production use
