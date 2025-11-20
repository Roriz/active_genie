# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Lister
    class JuriesTest < Minitest::Test
      def test_juries_database_design_proposal
        text = 'Database schema design for e-commerce platform with microservices architecture'
        criteria = 'Assess scalability, performance, and maintainability'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include database-related expertise
        db_roles = ['Database Architect', 'Data Engineer', 'System Architect', 'Performance Engineer',
                    'Backend Engineer']
        matching_roles = result.data.select { |jury| db_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include database expertise, full result: #{result}"
      end

      def test_juries_financial_analysis_report
        text = 'Quarterly financial performance analysis with revenue forecasting and investment recommendations'
        criteria = 'Evaluate analytical rigor, forecasting accuracy, and investment logic'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include financial expertise
        financial_roles = ['Financial Analyst', 'Investment Advisor', 'CFO', 'Equity Analyst', 'Risk Manager']
        matching_roles = result.data.select { |jury| financial_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include financial expertise, full result: #{result}"
      end

      def test_juries_business_strategy_plan
        text = 'Five-year strategic plan for expanding into international markets with operational roadmap'
        criteria = 'Assess strategic viability, market analysis depth, and execution feasibility'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include strategy and operations expertise
        strategy_roles = ['Strategy Consultant', 'Business Analyst', 'Operations Manager', 'Market Researcher',
                          'International Business Expert', 'Market Analysts']
        matching_roles = result.data.select { |jury| strategy_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include strategic expertise, full result: #{result}"
      end

      # Medical and Healthcare Tests
      def test_juries_medical_research_paper
        text = 'Clinical trial results for new diabetes medication showing efficacy and safety data'
        criteria = 'Evaluate research methodology, statistical analysis, and clinical significance'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include medical and research expertise
        medical_roles = ['Endocrinologist', 'Clinical Researcher', 'Biostatistician', 'Medical Writer',
                         'Regulatory Affairs Specialist']
        matching_roles = result.data.select { |jury| medical_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include medical expertise, full result: #{result}"
      end

      # Legal and Compliance Tests
      def test_juries_contract_analysis
        text = 'Software licensing agreement with complex intellectual property and liability clauses'
        criteria = 'Evaluate legal clarity, risk exposure, and enforceability'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include legal expertise
        legal_roles = ['Contract Attorney', 'Contract Lawyers', 'IP Lawyer', 'Intellectual Property Lawyers',
                       'Intellectual Property Lawyer', 'Technology Lawyer', 'Risk Analyst', 'Compliance Officer']
        matching_roles = result.data.select { |jury| legal_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include legal expertise, full result: #{result}"
      end

      def test_juries_regulatory_compliance_assessment
        text = 'GDPR compliance assessment for data processing operations in multinational corporation'
        criteria = 'Evaluate compliance thoroughness, risk identification, and remediation plans'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include privacy and compliance expertise
        compliance_roles = ['Privacy Officer', 'Compliance Specialist', 'Data Protection Officer', 'Legal Counsel',
                            'Risk Manager']
        matching_roles = result.data.select { |jury| compliance_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include compliance expertise, full result: #{result}"
      end

      # Educational Content Tests
      def test_juries_curriculum_design
        text = 'Computer science curriculum design for undergraduate program with practical project components'
        criteria = 'Assess educational objectives, industry relevance, and learning progression'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include educational and technical expertise
        education_roles = ['Computer Science Professor', 'Curriculum Designer', 'Educational Technologist',
                           'Industry Professional', 'Academic Advisor']
        matching_roles = result.data.select { |jury| education_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include educational expertise, full result: #{result}"
      end

      def test_juries_online_course_content
        text = 'Interactive online course content teaching data science fundamentals with hands-on exercises'
        criteria = 'Evaluate instructional design, content accuracy, and engagement effectiveness'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include instructional design and subject matter expertise
        instructional_roles = ['Instructional Designer', 'Data Scientist', 'E-learning Specialist', 'UX Designer',
                               'Educational Content Writer']
        matching_roles = result.data.select { |jury| instructional_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include instructional expertise, full result: #{result}"
      end

      # Creative and Design Tests
      def test_juries_brand_identity_design
        text = 'Complete brand identity package including logo, color palette, and style guidelines for tech startup'
        criteria = 'Assess brand coherence, market appeal, and design execution quality'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include design and branding expertise
        design_roles = ['Brand Designer', 'Graphic Designer', 'Creative Director', 'Marketing Specialist',
                        'Visual Designer']
        matching_roles = result.data.select { |jury| design_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include design expertise, full result: #{result}"
      end

      def test_juries_user_interface_mockups
        text = 'Mobile app user interface mockups for meditation and wellness application with accessibility features'
        criteria = 'Evaluate usability, accessibility compliance, and visual design quality'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include UX/UI and accessibility expertise
        ux_roles = ['UX Designer', 'UI Designer', 'Accessibility Specialist', 'Mobile App Designer', 'User Researcher']
        matching_roles = result.data.select { |jury| ux_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include UX/UI expertise, full result: #{result}"
      end

      # Environmental and Scientific Tests
      def test_juries_environmental_impact_study
        text = 'Environmental impact assessment for renewable energy installation with biodiversity considerations'
        criteria = 'Assess scientific rigor, environmental thoroughness, and mitigation strategies'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include environmental expertise
        environmental_roles = ['Environmental Scientist', 'Ecologist', 'Environmental Engineer',
                               'Conservation Biologist', 'Sustainability Expert']
        matching_roles = result.data.select { |jury| environmental_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include environmental expertise, full result: #{result}"
      end

      def test_juries_research_methodology_proposal
        text = 'Research methodology for studying climate change effects on urban heat islands using satellite data'
        criteria = 'Evaluate methodological soundness, data collection validity, and analytical approach'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include research and climate expertise
        research_roles = ['Climate Scientist', 'Remote Sensing Specialist', 'Urban Planner', 'Research Methodologist',
                          'Geospatial Analyst']
        matching_roles = result.data.select { |jury| research_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include research expertise, full result: #{result}"
      end

      def test_juries_complex_interdisciplinary_content
        text = 'AI ethics framework for healthcare applications addressing bias, privacy, and clinical decision support'
        criteria = 'Evaluate ethical comprehensiveness, practical applicability, and regulatory alignment'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include diverse expertise for complex topic
        interdisciplinary_roles = ['AI Ethics Expert', 'AI Ethicists', 'Healthcare Informaticist', 'Medical Ethicist',
                                   'Data Scientist', 'Regulatory Affairs Specialist', 'Clinical Researcher']
        matching_roles = result.data.select { |jury| interdisciplinary_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include relevant interdisciplinary expertise, full result: #{result}"
      end

      def test_juries_short_technical_content
        text = 'Bug fix for memory leak in C++ application'
        criteria = 'Evaluate fix completeness and code quality'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should include relevant technical expertise even for short content
        technical_roles = ['C++ Developer', 'Software Engineer', 'Performance Engineer', 'Systems Programmer']
        matching_roles = result.data.select { |jury| technical_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include technical expertise for code review, full result: #{result}"
      end

      def test_juries_reasoning_quality
        text = 'Machine learning model for predicting customer churn with feature engineering pipeline'
        criteria = 'Assess model performance, feature selection, and business applicability'

        result = ActiveGenie::Lister.with_juries(text, criteria)

        # Should have appropriate expertise
        ml_roles = ['Data Scientist', 'Machine Learning Engineer', 'Business Analyst', 'Customer Success Manager',
                    'Analytics Engineer']
        matching_roles = result.data.select { |jury| ml_roles.any? { |role| jury.include?(role) } }

        assert_operator matching_roles.length, :>=, 1,
                        "Should include ML expertise, full result: #{result}"
      end
    end
  end
end
