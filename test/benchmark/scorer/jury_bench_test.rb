# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Scorer
    class JuryBenchTest < Minitest::Test
      def test_evaluate_high_quality_code_implementation
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

        result = ActiveGenie::Scorer.by_jury_bench(
          code_snippet,
          'Evaluate code quality, readability, error handling, and algorithmic efficiency',
          ['senior_ruby_developer', 'code_architect']
        )

        assert_operator result['final_score'], :>=, 70,
                        "Expected high quality code to score >= 70, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_poor_marketing_copy
        marketing_text = "Buy our product its the best ever made trust me you need it now!!!"

        result = ActiveGenie::Scorer.by_jury_bench(
          marketing_text,
          'Evaluate marketing effectiveness, professionalism, and persuasive quality',
          ['marketing_director']
        )

        assert_operator result['final_score'], :>=, 5,
                        "Expected minimal score >= 5, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 35,
                        "Expected poor marketing copy <= 35, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_excellent_medical_documentation
        medical_content = "Patient shows significant improvement in cardiac function with ejection fraction increased from 45% to 62% following 12 weeks of ACE inhibitor therapy. No adverse effects reported. Recommend continued treatment with quarterly monitoring."

        result = ActiveGenie::Scorer.by_jury_bench(
          medical_content,
          'Evaluate medical accuracy, clarity, and clinical relevance',
          ['cardiologist', 'medical_writer']
        )

        assert_operator result['final_score'], :>=, 80,
                        "Expected excellent medical documentation >= 80, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_average_tutorial_content
        tutorial_content = "To create a new branch: 1) Open terminal 2) Navigate to repository 3) Run 'git checkout -b feature-name' 4) Start coding"

        result = ActiveGenie::Scorer.by_jury_bench(
          tutorial_content,
          'Evaluate instructional clarity, completeness, and beginner-friendliness',
          ['technical_educator']
        )

        assert_operator result['final_score'], :>=, 45,
                        "Expected average tutorial content >= 45, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 75,
                        "Expected tutorial to have improvement areas <= 75, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_professional_customer_support_response
        support_response = "I understand your frustration with the login issue. I've escalated this to our engineering team and will update you within 24 hours with a resolution. In the meantime, please try clearing your browser cache as a temporary workaround."

        result = ActiveGenie::Scorer.by_jury_bench(
          support_response,
          'Evaluate customer service quality, empathy, and solution orientation',
          ['customer_success_manager', 'support_specialist']
        )

        assert_operator result['final_score'], :>=, 75,
                        "Expected professional support response >= 75, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_technical_blog_post_excerpt
        blog_content = "AI will transform healthcare by enabling personalized treatments based on genetic profiles, real-time monitoring, and predictive analytics. Machine learning algorithms can analyze vast datasets to identify patterns invisible to human observers."

        result = ActiveGenie::Scorer.by_jury_bench(
          blog_content,
          'Evaluate accuracy of claims, writing quality, and audience engagement',
          ['medical_ai_expert']
        )

        assert_operator result['final_score'], :>=, 55,
                        "Expected decent technical content >= 55, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 85,
                        "Expected room for specificity <= 85, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_code_review_comment
        code_review = "Added rate limiting with sliding window algorithm, includes comprehensive unit tests covering edge cases, benchmarks show 99.9% accuracy with <10ms latency. Followed security best practices with input validation."

        result = ActiveGenie::Scorer.by_jury_bench(
          code_review,
          'Evaluate completeness, technical accuracy, and review quality',
          ['senior_developer', 'security_engineer']
        )

        assert_operator result['final_score'], :>=, 80,
                        "Expected thorough code review >= 80, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_regulatory_compliance_content
        compliance_content = "FDA-approved medical device with 99.9% accuracy demonstrated in three randomized controlled trials involving 2,847 participants across 15 clinical sites. Device meets ISO 13485 standards and 21 CFR Part 820 requirements."

        result = ActiveGenie::Scorer.by_jury_bench(
          compliance_content,
          'Evaluate regulatory compliance, claim substantiation, and medical accuracy',
          ['regulatory_affairs_specialist']
        )

        assert_operator result['final_score'], :>=, 85,
                        "Expected strong regulatory content >= 85, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_terrible_documentation
        terrible_docs = "just run the thing and it works idk figure it out yourself"

        result = ActiveGenie::Scorer.by_jury_bench(
          terrible_docs,
          'Evaluate documentation quality, helpfulness, and professional tone',
          ['technical_writer', 'developer_experience_engineer']
        )

        assert_operator result['final_score'], :>=, 0,
                        "Expected minimum score >= 0, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 25,
                        "Expected terrible documentation <= 25, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_excellent_api_documentation
        # add more depth in terms of examples and additional details that could improve developer experience and robustness
        api_docs = <<~DOCS
          ## Authentication
          All API requests require a valid API key in the Authorization header:
          ```
          Authorization: Bearer your_api_key_here
          ```
          
          ## Rate Limiting
          Requests are limited to 1000/hour per API key. Rate limit headers are included in responses:
          - `X-RateLimit-Limit`: Maximum requests per hour
          - `X-RateLimit-Remaining`: Requests remaining in current window

          ## Example Request
          ```
          GET /v1/users/12345
          Host: api.example.com
          Authorization: Bearer your_api_key_here
          ```
          
          ## Error Handling
          API returns standard HTTP status codes with descriptive error messages in JSON format.
        DOCS

        result = ActiveGenie::Scorer.by_jury_bench(
          api_docs,
          'Evaluate API documentation completeness, clarity, and developer experience',
          ['api_documentation_specialist']
        )

        assert_operator result['final_score'], :>=, 70,
                        "Expected excellent API docs >= 80, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_security_vulnerability_report
        security_report = <<~REPORT
          SQL injection vulnerability in user search endpoint. Unsanitized input allows arbitrary SQL execution. Severity: Critical.
          Reproduction steps:
          1) Navigate to /search
          2) Enter: ' OR 1=1-- in search field
          3) Database contents exposed

          Recommended remediation:
          - Implement input sanitization using prepared statements
          - Add parameterized queries to prevent SQL injection
          - Conduct security training for developers on secure coding practices

          Comunication to stakeholders:
          - For developers: Focus on technical remediation steps and secure coding practices
          - For management: Highlight business impact of potential data breaches and regulatory fines
        REPORT

        result = ActiveGenie::Scorer.by_jury_bench(
          security_report,
          'Evaluate security report quality, severity assessment, and actionability',
          ['security_analyst', 'penetration_tester']
        )

        assert_operator result['final_score'], :>=, 80,
                        "Expected excellent security report >= 80, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_user_experience_feedback
        ux_feedback = "The checkout process is confusing - took me 10 minutes to find the payment button, and I accidentally ordered twice because the confirmation was unclear. Consider simplifying the flow and adding better visual cues."

        result = ActiveGenie::Scorer.by_jury_bench(
          ux_feedback,
          'Evaluate feedback quality, specificity, and actionable insights',
          ['ux_designer']
        )

        assert_operator result['final_score'], :>=, 70,
                        "Expected good UX feedback >= 70, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 90,
                        "Expected room for more detail <= 90, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_business_proposal_excerpt
        business_proposal = "Our SaaS platform reduces operational costs by 40% through AI-powered automation. Target market of 50,000 mid-size companies with $2M+ revenue. Conservative projections show $10M ARR by year 3 with 15% market penetration."

        result = ActiveGenie::Scorer.by_jury_bench(
          business_proposal,
          'Evaluate business viability, market analysis quality, and financial projections',
          ['business_analyst', 'venture_capitalist']
        )

        assert_operator result['final_score'], :>=, 60,
                        "Expected decent business proposal >= 60, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
        assert_operator result['final_score'], :<=, 85,
                        "Expected need for more validation <= 85, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end

      def test_evaluate_academic_research_abstract
        research_abstract = <<~ABSTRACT
        This study examines the efficacy of machine learning algorithms in predicting stock market volatility
        using sentiment analysis of social media data. A dataset of 1.2M tweets was analyzed using BERT-based models,
        achieving 73% accuracy in predicting next-day volatility with statistical significance (p<0.001).

        # Methodology
        We collected a dataset of 1.2 million tweets related to stock market sentiment, preprocessed the text using BERT embeddings,
        and trained a series of machine learning models including Random Forest, XGBoost, and LSTM networks.

        # statistical analysis details
        Statistical significance was assessed using a two-tailed t-test with p-value < 0.05. The models were evaluated
        on a holdout test set of 300,000 tweets, achieving an F1 score of 0.72 and precision of 0.75.
        ABSTRACT

        result = ActiveGenie::Scorer.by_jury_bench(
          research_abstract,
          'Evaluate research methodology, statistical rigor, and academic writing quality',
          ['research_scientist']
        )

        assert_operator result['final_score'], :>=, 75,
                        "Expected solid research abstract >= 75, but was #{result['final_score']}, " \
                        "because: #{result['final_reasoning']}"
      end
    end
  end
end
