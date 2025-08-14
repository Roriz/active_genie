# Scorer

The **Scorer** module provides objective evaluation of text content using AI-powered expert reviewers. It assigns numerical scores (0-100) along with detailed reasoning, making it perfect for quality assessment, content evaluation, and automated review processes.

The evaluation process follows a structured approach:

- Multiple expert reviewers independently evaluate the content against specified criteria
- Each reviewer provides both a numerical score (0-100) and detailed reasoning
- A final aggregated score is calculated based on all reviewer assessments
- When no reviewers are specified, the system automatically recommends appropriate experts

**Note:** The number of reviewers and scoring methodology can be customized to fit specific evaluation needs.

## Features
- **Multi-reviewer evaluation** - Get scores and feedback from multiple AI-powered expert reviewers
- **Automatic reviewer selection** - Smart recommendation of reviewers based on content and criteria
- **Detailed feedback** - Comprehensive reasoning for each reviewer's score with specific strengths and improvement areas
- **Standardized scoring** - Consistent 0-100 scale with defined quality tiers (Terrible, Bad, Average, Good, Great)
- **Flexible criteria** - Score text against any specified evaluation criteria or rubric

## Basic Usage

Evaluate content with predefined expert reviewers:

```ruby
content = "The implementation uses dependency injection for better testability and follows SOLID principles"
criteria = "Evaluate code quality, maintainability, and adherence to best practices"
reviewers = ["Senior Software Engineer", "Code Architect"]

result = ActiveGenie::Scorer.call(content, criteria, reviewers)
# => {
#      "senior_software_engineer_score" => 92,
#      "senior_software_engineer_reasoning" => "Excellent use of dependency injection which enhances testability. SOLID principles are well-applied, making the code maintainable and extensible.",
#      "code_architect_score" => 89,
#      "code_architect_reasoning" => "Strong architectural decisions with dependency injection. Minor improvements could be made in documentation and error handling patterns.",
#      "final_score" => 90.5,
#      "final_reasoning" => "Both reviewers agree on the high quality of the implementation, particularly praising the dependency injection and SOLID principles application."
#    }
```

## Automatic Reviewer Selection

When no reviewers are specified, the system intelligently recommends appropriate experts based on content and criteria:

```ruby
content = "Patient shows significant improvement in cardiac function with ejection fraction increased from 45% to 62%"
criteria = "Evaluate medical accuracy, clarity, and clinical relevance"

result = ActiveGenie::Scorer.call(content, criteria)
# => {
#      "cardiologist_score" => 94,
#      "cardiologist_reasoning" => "Clinically significant improvement in ejection fraction indicates excellent therapeutic response. The measurement is within normal ranges.",
#      "medical_writer_score" => 87,
#      "medical_writer_reasoning" => "Clear and concise medical communication. Could benefit from additional context about treatment duration and patient demographics.",
#      "clinical_researcher_score" => 91,
#      "clinical_researcher_reasoning" => "Objective measurement shows substantial clinical improvement. Data presentation follows standard medical reporting practices.",
#      "final_score" => 90.7,
#      "final_reasoning" => "All reviewers confirm the high quality of the medical assessment, with particular strength in objective measurement reporting."
#    }
```

## Scoring Scale

The Scorer uses a standardized 0-100 scale with clear quality tiers:

- **Terrible (0-20)**: Content does not meet the criteria and requires significant revision
- **Bad (21-40)**: Content is substandard but meets some basic criteria
- **Average (41-60)**: Content meets criteria adequately with room for improvement
- **Good (61-80)**: Content exceeds criteria and demonstrates above-average quality
- **Great (81-100)**: Content exceeds all expectations and represents exceptional quality

## Advanced Usage Examples

### Content Quality Assessment
```ruby
blog_post = "AI will transform healthcare by enabling personalized treatments..."
criteria = "Evaluate accuracy of claims, writing quality, and audience engagement"

result = ActiveGenie::Scorer.call(blog_post, criteria, ["Medical AI Expert", "Technical Writer"])
```

### Code Review Automation
```ruby
code_review = "Added rate limiting with sliding window algorithm, includes unit tests and benchmarks"
criteria = "Evaluate completeness, technical accuracy, and review quality"

result = ActiveGenie::Scorer.call(code_review, criteria, ["Senior Developer"])
```

### Marketing Effectiveness
```ruby
marketing_copy = "Revolutionary AI-powered smart home system that learns your preferences"
criteria = "Evaluate marketing effectiveness and accuracy of technical claims"

result = ActiveGenie::Scorer.call(marketing_copy, criteria, ["Marketing Specialist"])
```

### Educational Content
```ruby
tutorial = "Step 1: Click 'Forgot Password', Step 2: Enter email, Step 3: Check inbox..."
criteria = "Evaluate clarity, completeness, and instructional effectiveness"

result = ActiveGenie::Scorer.call(tutorial, criteria, ["UX Writer", "Instructional Designer"])
```

## Tips

- **Be specific with evaluation criteria.** The more detailed your criteria, the more accurate and actionable the scoring will be. Instead of "evaluate quality," specify what quality means in your context.
- **Choose relevant reviewers when possible.** While automatic reviewer selection is powerful, manually specifying domain experts often yields more targeted feedback.
- **Consider the content domain.** Technical content benefits from technical reviewers, while creative content may need different expertise.
- **Use descriptive criteria that match your goals.** Are you evaluating for accuracy, clarity, engagement, compliance, or creative merit? Each requires different evaluation approaches.
- **Leverage the detailed reasoning.** The individual reviewer feedback often contains more actionable insights than the numerical scores alone.
- **Don't rely solely on the raw output** - while useful for debugging, the raw response structure may change. Use the structured fields instead.

## Interface

### `.call(text, criteria, reviewers = [], config: {})`
Main interface for scoring text content with expert evaluation.

#### Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | String | The text content to evaluate and score |
| `criteria` | String | The evaluation criteria, rubric, or standards to assess against |
| `reviewers` | Array of String | Optional list of expert reviewer roles (auto-selected if empty) |
| `config` | Hash | Additional configuration options for scoring behavior |

#### Returns
Hash containing detailed scoring results:
- `{reviewer_name}_score` [Number] - Individual reviewer scores (0-100)
- `{reviewer_name}_reasoning` [String] - Detailed explanation from each reviewer
- `final_score` [Number] - Aggregated final score based on all reviewers
- `final_reasoning` [String] - Summary reasoning explaining the final score

-----

### `.jury_bench(text, criteria, reviewers = [], config: {})`
Alternative interface name for scoring text content with jury-style evaluation. Functionally identical to `.call()`.

### Usage Notes
- **Best suited for objective evaluation** of text content where consistent scoring is important
- **Automatic reviewer recommendation** works best when criteria clearly indicate the domain or expertise needed
- **Multiple reviewers provide balanced perspective** but may increase processing time
- **Detailed reasoning helps understand scoring decisions** and identify specific improvement areas
- **Consistent 0-100 scale** enables easy comparison across different content and criteria

**Performance Impact:** Using multiple reviewers or requesting detailed feedback may increase processing time and costs. Consider balancing thoroughness with efficiency needs.

## Practical Applications

### Code Quality Assessment
Evaluate code implementations, pull requests, and technical documentation:

```ruby
code_snippet = <<~CODE
  def calculate_user_score(user_actions, weights = {})
    return 0 if user_actions.empty?
    
    total_score = user_actions.sum do |action|
      weight = weights[action[:type]] || 1.0
      action[:value] * weight
    end
    
    [total_score / user_actions.size, 100].min
  end
CODE

criteria = "Evaluate code quality, readability, error handling, and algorithmic efficiency"
result = ActiveGenie::Scorer.call(code_snippet, criteria, ["Senior Ruby Developer"])
```

### Content Marketing Evaluation
Score marketing copy, blog posts, and promotional materials:

```ruby
marketing_text = "Transform your workflow with our AI-powered automation platform that reduces manual tasks by 80%"
criteria = "Evaluate marketing effectiveness, claim accuracy, and audience appeal"

result = ActiveGenie::Scorer.call(marketing_text, criteria, ["Marketing Director", "Product Manager"])
```

### Academic & Educational Content
Assess educational materials, tutorials, and instructional content:

```ruby
tutorial_step = "To create a new branch: 1) Open terminal 2) Navigate to repository 3) Run 'git checkout -b feature-name'"
criteria = "Evaluate instructional clarity, completeness, and beginner-friendliness"

result = ActiveGenie::Scorer.call(tutorial_step, criteria, ["Technical Educator"])
```

### Customer Feedback Analysis
Score and analyze customer reviews, support responses, and feedback:

```ruby
support_response = "I understand your frustration with the login issue. I've escalated this to our engineering team and will update you within 24 hours with a resolution."
criteria = "Evaluate customer service quality, empathy, and solution orientation"

result = ActiveGenie::Scorer.call(support_response, criteria, ["Customer Success Manager"])
```

### Compliance & Quality Assurance
Evaluate content for regulatory compliance, brand standards, and quality guidelines:

```ruby
product_description = "FDA-approved medical device with 99.9% accuracy in clinical trials"
criteria = "Evaluate regulatory compliance, claim substantiation, and medical accuracy"

result = ActiveGenie::Scorer.call(product_description, criteria, ["Regulatory Affairs Specialist", "Medical Writer"])
```
