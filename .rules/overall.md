# ActiveGenie Developer Documentation

## Overview

ActiveGenie is a Ruby gem designed as "The Lodash for GenAI" - providing consistent, model-agnostic utilities for common GenAI workflows. The codebase is structured as a modular library with five core modules: **Extractor**, **Comparator**, **Scorer**, **Ranker**, and **Lister**.

## Project Structure & Patterns

### Root Directory Layout

```
active_genie/
├── lib/                    # Main library code
├── test/                   # Test suite (unit & integration)
├── docs/                   # Documentation website
├── bin/                    # Build and publish scripts
├── tmp/                    # Temporary development files, put any memory or auxiliary files here
└── log/                    # Application logs
```

### Core Architecture Patterns

1. **Module-based Design**: Each major feature is organized as a separate module under `lib/active_genie/`
2. **Configuration-driven**: Centralized configuration system with provider-specific configs
3. **Client Abstraction**: Unified client interface for multiple AI providers (OpenAI, Anthropic, Google, DeepSeek)
4. **Prompt Engineering**: Template-based prompts with JSON schema for function calling
5. **Autoload Pattern**: Uses Ruby's autoload for lazy loading of modules

## Core Library Structure (`lib/active_genie/`)

### Main Entry Point
- **`active_genie.rb`**: Primary module file with autoloading and configuration initialization
- **`configuration.rb`**: Central configuration management with sub-configs for each module

### Core Modules

#### 1. **Extractor** (`extractor/`)
**Purpose**: Extract structured data from unstructured text using AI
- `explanation.rb`: Main extraction with reasoning explanations
- `litote.rb`: Extraction from informal text like chat messages, including safety figures of speech
- Pattern: Each extractor has `.rb`, `.json` (schema), and `.prompt.md` (template) files

#### 2. **Comparator** (`comparator/`)
**Purpose**: Compare and evaluate content between two players
- `debate.rb`: Political debate comparison engine
- `fight.rb`: Specialized combat/competition comparison engine
- Pattern: Uses structured responses with winner/loser/reasoning

#### 3. **Scorer** (`scorer/`)
**Purpose**: Score content quality using AI evaluation
- `jury_bench.rb`: Multi-criteria scoring system

#### 4. **Ranker** (`ranker/`)
**Purpose**: Rank and order items using various algorithms
- `elo.rb`: ELO rating system implementation
- `free_for_all.rb`: Multi-participant ranking
- `tournament.rb`: Tournament-style ranking
- `scoring.rb`: Score-based ranking
- `entities/`: Data structures for ranker entities

### Supporting Infrastructure

#### **Clients** (`clients/`)
- **`base_client.rb`**: Abstract HTTP client with retry logic, timeout handling
- **`unified_client.rb`**: Main interface that delegates to provider-specific clients
- **Provider Clients**: `openai_client.rb`, `anthropic_client.rb`, `google_client.rb`, `deepseek_client.rb`
- **Pattern**: Each provider implements the same interface, unified client handles routing

#### **Configuration** (`configs/`)
- Modular configuration system with separate config classes per module
- **`providers/`**: Provider-specific configuration (API keys, endpoints, models)
- Pattern: Each module has its own `*_config.rb` file

#### **Utilities**
- **`logger.rb`**: Centralized logging system

### Error Handling (`errors/`)
- Custom exception classes for specific error conditions
- **`invalid_provider_error.rb`**: Provider validation errors
- **`invalid_log_output_error.rb`**: Logging configuration errors
Errors are raised with clear messages to help developers debug issues quickly. Should be informative and actionable, guiding developers to resolve issues efficiently.

## Development Patterns & Conventions

### 1. **Module Structure Pattern**
Each core module follows this pattern:
```
module_name/
├── methodology/           # subdirectory for implementation details if needed
├── methodology.rb           # Methodology implementation
├── methodology.json             # JSON schema for AI function calling
├── methodology.prompt.md              # Prompt template
```
each module can have multiple methodologies, allowing for different approaches to the same problem.

### 2. **AI Integration Pattern**
- Uses **function calling** with structured JSON schemas
- **Prompt templates** stored as separate `.md` files
- **Unified client** abstracts provider differences
- **Configuration-driven** model and provider selection

### 3. **Configuration Pattern**
```ruby
# Hierarchical configuration
ActiveGenie.configure do |config|
  config.providers.openai.api_key = "..."
  config.scorer.default_criteria = "..."
  config.log.level = :info
end
```

### 4. **Response Structure Pattern**
Consistent response objects across modules:
```ruby
# Comparator example
ComparatorResponse = Struct.new(:winner, :loser, :reasoning, :raw, keyword_init: true)
```

### 5. **Delegation Pattern**
Top-level modules delegate to specific implementations:
```ruby
module Comparator
  def_delegator :Debate, :call
  def_delegator :Debate, :call, :by_debate
  def_delegator :Fight, :call, :by_fight
end
```

## Testing Strategy

### Test Organization
```
test/
├── unit/                   # Unit tests for individual classes
│   ├── configuration_test.rb
│   ├── comparator/
│   ├── extractor/
│   └── ranker/
└── integration/            # End-to-end integration tests
    ├── rails_latest_test.rb
└── benchmark/            # Datasets and benchmarks for each module
    ├── comparator/
    ├── extractor/
    ├── ranker/
    └── scorer/
```

### Benchmarking System
- **`benchmark/`**: Performance and accuracy benchmarking
- **`test_cases/`**: Standardized test scenarios
- Ensures consistency across AI providers and versions

## Key Dependencies & Requirements

- **Ruby 3.4.0+**: Minimum required version
- **HTTP Client**: Built-in Net::HTTP with custom retry logic
- **No Dependency**: Pure Ruby gem
- **Rake Tasks**: Build, test, and benchmark automation

## Development Workflow

### Installation & Setup
```ruby
# Gemfile
gem 'active_genie'

# Rakefile (for Rails integration)
echo "ActiveGenie.load_tasks" >> Rakefile

# Generate configuration
rails active_genie:install
```

### Adding New Modules
1. Create module directory under `lib/active_genie/`
2. Implement main class with `.call` class method
3. Add configuration class in `configs/`
4. Update main `configuration.rb` to include new config
5. Add autoload entry in main `active_genie.rb`
6. Create corresponding tests

### Provider Integration
1. Create new client in `clients/`
2. Inherit from `BaseClient`
3. Implement required methods
4. Add provider config in `configs/providers/`
5. Update `UnifiedClient` routing logic

## Design Philosophy

1. **Developer-First**: Simple, consistent APIs across all modules
2. **Model-Agnostic**: Works with any AI provider through unified interface
3. **Future-Proof**: Abstraction layer protects against AI ecosystem changes
4. **Reliability**: Built-in retry logic, error handling, and benchmarking
5. **Modularity**: Use only what you need, each module is independent
6. **Convention over Configuration**: Sensible defaults with customization options

This architecture enables developers to build reliable GenAI features without worrying about the rapidly changing AI landscape, while maintaining consistency and performance across different providers and models.