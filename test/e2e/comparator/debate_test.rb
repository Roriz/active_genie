# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Comparator
    class DebateTest < Minitest::Test
      TESTS = [
        { input: ['american food', 'brazilian food', 'less fat is better'], expected: 1 },
        { input: ['rainning day', 'sunny day', 'go to park with family'], expected: 1 },
        { input: ['python', 'javascript', 'data science and machine learning tasks'], expected: 0 },
        { input: ['bicycle', 'car', 'environmentally friendly urban commuting'], expected: 0 },
        { input: ['reading a book', 'watching tv', 'cognitive development and relaxation'], expected: 0 },
        { input: ['yoga', 'weightlifting', 'stress relief and flexibility improvement'], expected: 0 },
        { input: ['online course', 'in-person class', 'flexible schedule and cost effectiveness'], expected: 0 },
        { input: ['video call', 'text message', 'discussing complex emotional topics'], expected: 0 },
        { input: ['remote work', 'office work', 'work-life balance and productivity'], expected: 0 },
        { input: ['Kiki', 'Bouba', 'what sounds is more aggressive?'], expected: 0 }
      ].freeze

      TESTS.each_with_index do |test, index|
        define_method("test_#{test[:input][2].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
          result = ActiveGenie::Comparator.by_debate(*test[:input])

          assert_equal test[:input][test[:expected]], result.data
        end
      end

      def test_dress_for_friday_night
        dresses = [
          'Experience ultimate comfort with our Cozy Cielo Home Dress. Made from a soft cotton ' \
          'blend, it features a relaxed fit, scoop neckline, and convenient side pockets. ' \
          'Available in calming colors, this knee-length dress ensures you look chic while ' \
          'feeling at ease. Easy to care for and machine washable, it\'s a versatile wardrobe ' \
          'staple you\'ll love.',
          'Turn heads with our Glamour Noir Dress. Crafted from a luxurious, shimmering fabric, ' \
          'this dress features a sleek, form-fitting silhouette and an elegant V-neckline. The ' \
          'midi length and sophisticated design promise a stunning look, while the subtle side ' \
          'slit adds a touch of allure. Available in timeless black, the Glamour Noir Dress is ' \
          'perfect for dinners or nights out. Effortlessly chic and machine washable, it\'s the ' \
          'go-to choice for your next night on the town.'
        ]
        criteria = 'Dress for Friday night'
        result = ActiveGenie::Comparator.by_debate(
          dresses[0],
          dresses[1],
          criteria
        )

        assert_equal dresses[1], result.data
      end

      def test_stackoverflow_questions
        stackoverflow_issues = [
          'I\'ve ruled out race conditions, but JIT optimizations might be reordering ' \
          'instructions unpredictably. Profiling suggests a cache coherency issue, possibly ' \
          'tied to memory fences or weak memory ordering on ARM. Has anyone encountered a ' \
          'similar JIT-induced anomaly that only manifests under specific CPU architectures?',
          'How do I print "Hello, World!" in Python?'
        ]
        criteria = 'What is the most hardest question'
        result = ActiveGenie::Comparator.by_debate(
          stackoverflow_issues[0],
          stackoverflow_issues[1],
          criteria
        )

        assert_equal stackoverflow_issues[0], result.data
      end

      def test_code_quality_comparison
        implementations = [
          'Implementation uses dependency injection for better testability. The service layer ' \
          'is properly abstracted with clear interfaces. Unit tests cover 95% of the codebase ' \
          'with both positive and negative test cases. Error handling is comprehensive with ' \
          'custom exceptions and proper logging. The architecture follows SOLID principles.',
          'Code has high test coverage at 98% but tightly coupled components throughout. ' \
          'Business logic is mixed with presentation layer. No dependency injection used, ' \
          'making testing difficult. Global state is heavily relied upon. Error handling ' \
          'uses generic exceptions with minimal context.'
        ]
        criteria = 'Evaluate code quality and maintainability for long-term enterprise development'
        result = ActiveGenie::Comparator.by_debate(
          implementations[0],
          implementations[1],
          criteria
        )

        assert_equal implementations[0], result.data
      end

      def test_smartphone_comparison_for_photography
        phones = [
          'iPhone 15 Pro features a 48MP main camera with optical image stabilization, ' \
          'ProRAW support, and computational photography. The camera app is intuitive with ' \
          'professional controls easily accessible. Video recording supports 4K ProRes. ' \
          'Night mode works exceptionally well in low light conditions. Portrait mode ' \
          'creates natural bokeh effects.',
          'Samsung Galaxy S24 Ultra boasts a 200MP main sensor with advanced AI processing, ' \
          'periscope telephoto lens with 10x optical zoom, and Space Zoom up to 100x. ' \
          'Expert RAW app provides DSLR-like controls. 8K video recording capability. ' \
          'Excellent macro photography with dedicated lens. S Pen integration for precise ' \
          'photo editing on device.'
        ]
        criteria = 'Best smartphone for professional photography and content creation, ' \
                   'considering image quality, versatility, and ease of use'
        result = ActiveGenie::Comparator.by_debate(
          phones[0],
          phones[1],
          criteria
        )

        # Both are strong contenders, but testing the debate logic
        refute_nil result.data
        refute_nil result.reasoning
        assert_includes [phones[0], phones[1]], result.data
      end

      def test_learning_platform_comparison
        platforms = [
          'Coursera offers university-partnered courses with academic rigor and accredited ' \
          'certificates. Courses include peer-reviewed assignments, structured timelines, ' \
          'and professor-led video lectures. Financial aid available for verified certificates. ' \
          'Mobile app supports offline viewing. Discussion forums foster peer interaction.',
          'YouTube provides free, diverse content from industry experts and practitioners. ' \
          'No enrollment deadlines or structured curriculum constraints. Comments section ' \
          'allows direct interaction with creators. Playlists can create custom learning paths. ' \
          'Real-world examples and case studies are abundant. No certificates but practical ' \
          'knowledge gain.'
        ]
        criteria = 'Best platform for learning web development on a tight budget with ' \
                   'flexible schedule requirements'
        result = ActiveGenie::Comparator.by_debate(
          platforms[0],
          platforms[1],
          criteria
        )

        assert_equal platforms[0], result.data
      end

      def test_transportation_for_urban_commute
        options = [
          'Electric bike offers 50-mile range on single charge, can use bike lanes to ' \
          'avoid traffic, costs $0.05 per mile in electricity, provides exercise benefits, ' \
          'requires no parking fees, can be stored indoors, weather dependent, requires ' \
          'physical effort on hills, limited cargo capacity.',
          'Public transit subway system runs every 5 minutes during peak hours, climate ' \
          'controlled, can read or work during commute, monthly pass costs $120, covers ' \
          'entire metropolitan area, wheelchair accessible, occasional delays during rush hour, ' \
          'crowded during peak times, requires walking to stations.'
        ]
        criteria = 'Daily commute of 8 miles in a metropolitan city, prioritizing cost ' \
                   'efficiency, environmental impact, and reliability during all weather conditions'
        result = ActiveGenie::Comparator.by_debate(
          options[0],
          options[1],
          criteria
        )

        refute_nil result.data
        refute_nil result.reasoning
        assert_includes [options[0], options[1]], result.data
      end

      def test_database_architecture_decision
        databases = [
          'PostgreSQL offers ACID compliance with strong consistency guarantees, supports ' \
          'complex queries with advanced SQL features, has excellent performance for ' \
          'analytical workloads, provides full-text search capabilities, supports JSON ' \
          'data types, has mature ecosystem with extensive tooling, requires vertical ' \
          'scaling for very large datasets.',
          'MongoDB provides flexible document schema perfect for rapid prototyping, ' \
          'horizontal scaling across multiple servers, built-in sharding for large datasets, ' \
          'natural fit for JSON-based applications, replica sets for high availability, ' \
          'eventual consistency model, lacks complex join operations, requires careful ' \
          'query optimization.'
        ]
        criteria = 'Database selection for a financial application requiring strict data ' \
                   'consistency, complex reporting, and audit trail capabilities'
        result = ActiveGenie::Comparator.by_debate(
          databases[0],
          databases[1],
          criteria
        )

        assert_equal databases[0], result.data
      end

      def test_investment_strategy_comparison
        strategies = [
          'Dollar-cost averaging involves investing fixed amount monthly regardless of ' \
          'market conditions, reduces impact of volatility through time diversification, ' \
          'requires minimal market timing skills, builds disciplined investing habits, ' \
          'historically successful over 10+ year periods, may miss opportunities during ' \
          'market crashes, steady but potentially lower returns.',
          'Value investing focuses on undervalued stocks trading below intrinsic value, ' \
          'requires extensive fundamental analysis and research skills, potential for ' \
          'significant returns when market corrects, worked successfully for Warren Buffett, ' \
          'requires patience and contrarian mindset, higher risk of picking value traps, ' \
          'time-intensive research required.'
        ]
        criteria = 'Investment approach for busy professional with limited time for research, ' \
                   'seeking steady long-term growth for retirement planning'
        result = ActiveGenie::Comparator.by_debate(
          strategies[0],
          strategies[1],
          criteria
        )

        assert_equal strategies[0], result.data
      end

      def test_web_framework_for_startup
        frameworks = [
          'Ruby on Rails provides convention over configuration philosophy, rapid ' \
          'prototyping capabilities, mature ecosystem with extensive gems, built-in ' \
          'security features, excellent for CRUD applications, active developer community, ' \
          'may have performance limitations at scale, opinionated structure.',
          'React with Node.js offers component-based architecture, excellent performance ' \
          'with virtual DOM, large talent pool availability, great for single-page ' \
          'applications, flexible and unopinionated, strong ecosystem, requires more ' \
          'setup and configuration decisions, steeper learning curve for full-stack.'
        ]
        criteria = 'Web framework selection for MVP development of a social media startup ' \
                   'with limited budget and need for rapid iteration'
        result = ActiveGenie::Comparator.by_debate(
          frameworks[0],
          frameworks[1],
          criteria
        )

        assert_equal frameworks[0], result.data
      end

      def test_exercise_routine_for_busy_parent
        routines = [
          'High-Intensity Interval Training (HIIT) workouts require only 20-30 minutes, ' \
          'can be done at home without equipment, burns calories efficiently, improves ' \
          'cardiovascular health quickly, flexible timing fits around kids\' schedules, ' \
          'bodyweight exercises like burpees and mountain climbers, requires high intensity ' \
          'which may be challenging after long workdays.',
          'Yoga practice offers stress relief and flexibility improvement, can involve ' \
          'children in family yoga sessions, improves mental health and sleep quality, ' \
          'gentle on joints and suitable for all fitness levels, online classes available ' \
          'anytime, builds core strength gradually, progress may be slower than intense cardio, ' \
          'requires consistency for visible results.'
        ]
        criteria = 'Exercise routine for working parent with two young children, limited ' \
                   'time, and high stress levels, focusing on both physical and mental health'
        result = ActiveGenie::Comparator.by_debate(
          routines[0],
          routines[1],
          criteria
        )

        refute_nil result.data
        refute_nil result.reasoning
        assert_includes [routines[0], routines[1]], result.data
      end

      def test_cloud_provider_for_ecommerce
        providers = [
          'Amazon Web Services offers comprehensive e-commerce services including managed ' \
          'databases, CDN, auto-scaling groups, and payment processing integration. ' \
          'Marketplace experience with Amazon Pay, robust security compliance (PCI DSS), ' \
          'global infrastructure with edge locations, extensive monitoring and analytics, ' \
          'can be expensive for small businesses, complex pricing structure.',
          'Google Cloud Platform provides excellent machine learning capabilities for ' \
          'personalization, competitive pricing with sustained use discounts, superior ' \
          'data analytics with BigQuery, Kubernetes-native architecture, strong performance ' \
          'for global applications, fewer specialized e-commerce services compared to AWS, ' \
          'smaller partner ecosystem.'
        ]
        criteria = 'Cloud platform for medium-sized e-commerce business expecting rapid ' \
                   'growth, requiring personalization features and global scalability'
        result = ActiveGenie::Comparator.by_debate(
          providers[0],
          providers[1],
          criteria
        )

        refute_nil result.data
        refute_nil result.reasoning
        assert_includes [providers[0], providers[1]], result.data
      end

      def test_communication_tool_for_remote_team
        tools = [
          'Slack provides organized channel-based communication, extensive app integrations ' \
          'with development tools, threaded conversations to reduce noise, custom emoji ' \
          'and reactions for team culture, searchable message history, workflow automation ' \
          'with bots, can become overwhelming with many channels, notifications can be ' \
          'distracting, limited video call functionality.',
          'Microsoft Teams offers seamless integration with Office 365 suite, excellent ' \
          'video conferencing capabilities, file collaboration within conversations, ' \
          'enterprise-grade security and compliance, calendar integration, whiteboard ' \
          'feature for brainstorming, can feel heavy and slow, less customizable than Slack, ' \
          'chat organization not as intuitive.'
        ]
        criteria = 'Communication platform for distributed software development team of 25 ' \
                   'people, requiring integration with development workflow and daily standups'
        result = ActiveGenie::Comparator.by_debate(
          tools[0],
          tools[1],
          criteria
        )

        assert_equal tools[0], result.data
      end

      def test_home_security_system_comparison
        systems = [
          'Professional monitoring service provides 24/7 surveillance center response, ' \
          'immediate emergency service dispatch, cellular backup communication, professional ' \
          'installation and maintenance, insurance discounts available, monthly fees of ' \
          '$40-60, requires long-term contracts, limited customization options.',
          'DIY smart security system offers complete customization and control, one-time ' \
          'purchase cost with no monthly fees, smartphone app monitoring, easy installation ' \
          'and expansion, integration with smart home devices, no professional monitoring ' \
          'response, requires technical knowledge for setup, dependent on home internet connection.'
        ]
        criteria = 'Home security solution for tech-savvy homeowner on fixed budget, ' \
                   'prioritizing cost-effectiveness and customization over professional monitoring'
        result = ActiveGenie::Comparator.by_debate(
          systems[0],
          systems[1],
          criteria
        )

        assert_equal systems[1], result.data
      end

      def test_laptop_for_creative_professional
        laptops = [
          'MacBook Pro M3 Max features exceptional performance for video editing and 3D ' \
          'rendering, industry-standard color accuracy with P3 display, excellent battery ' \
          'life lasting 12+ hours, silent operation under heavy workloads, optimized ' \
          'software ecosystem for creative apps, premium build quality, expensive price point, ' \
          'limited port selection requiring dongles.',
          'Dell XPS 15 OLED provides stunning 4K OLED display with perfect blacks, powerful ' \
          'NVIDIA RTX graphics for 3D work, extensive port selection including USB-A and HDMI, ' \
          'more affordable than MacBook Pro, Windows compatibility with broader software selection, ' \
          'shorter battery life around 6-8 hours, heavier weight, potential thermal throttling.'
        ]
        criteria = 'Laptop selection for freelance video editor and motion graphics designer ' \
                   'who travels frequently and needs reliable performance for client work'
        result = ActiveGenie::Comparator.by_debate(
          laptops[0],
          laptops[1],
          criteria
        )

        assert_equal laptops[0], result.data
      end

      def test_programming_language_for_ai_project
        languages = [
          'Python dominates AI/ML ecosystem with libraries like TensorFlow, PyTorch, and ' \
          'scikit-learn, extensive documentation and tutorials available, large community ' \
          'support, Jupyter notebook integration for research, simple syntax accelerates ' \
          'prototyping, slower execution speed compared to compiled languages, GIL limitations ' \
          'for true multithreading.',
          'Julia designed specifically for high-performance scientific computing, near C-speed ' \
          'execution with Python-like syntax, excellent parallel computing capabilities, ' \
          'growing AI/ML library ecosystem, first-class support for mathematical operations, ' \
          'smaller community and fewer resources, less mature tooling compared to Python, ' \
          'steeper learning curve.'
        ]
        criteria = 'Programming language for machine learning research project requiring ' \
                   'both rapid prototyping and high-performance computation for large datasets'
        result = ActiveGenie::Comparator.by_debate(
          languages[0],
          languages[1],
          criteria
        )

        refute_nil result.data
        refute_nil result.reasoning
        assert_includes [languages[0], languages[1]], result.data
      end

      def test_meal_prep_strategy_for_healthy_eating
        strategies = [
          'Sunday batch cooking involves preparing entire meals in large quantities, ' \
          'containers ready for grab-and-go convenience, ensures consistent nutrition, ' \
          'saves significant time during busy weekdays, reduces food waste through planning, ' \
          'cost-effective bulk ingredient purchases, meals may become repetitive, food quality ' \
          'degrades over week, requires large time investment on weekends.',
          'Daily fresh cooking uses minimal preparation, ingredients stay fresh, variety ' \
          'in daily meals prevents boredom, can adapt to daily cravings and energy levels, ' \
          'cooking can be meditative and stress-relieving, requires daily time commitment, ' \
          'higher grocery costs, may lead to unhealthy choices when tired, more dishes to clean.'
        ]
        criteria = 'Meal strategy for busy professional working 50+ hours per week, ' \
                   'prioritizing nutrition, time efficiency, and maintaining variety in diet'
        result = ActiveGenie::Comparator.by_debate(
          strategies[0],
          strategies[1],
          criteria
        )

        assert_equal strategies[0], result.data
      end

      def test_cryptocurrency_investment_approach
        approaches = [
          'Bitcoin-focused strategy concentrates on digital gold narrative, proven track ' \
          'record over 15 years, highest liquidity and institutional adoption, store of value ' \
          'properties, regulatory clarity improving, simpler portfolio management, limited ' \
          'utility beyond store of value, environmental concerns, potential for missed ' \
          'opportunities in other crypto sectors.',
          'Diversified altcoin portfolio includes DeFi tokens, smart contract platforms, ' \
          'and utility tokens, higher growth potential than Bitcoin, exposure to innovation ' \
          'in blockchain technology, opportunities in emerging sectors like NFTs and gaming, ' \
          'much higher volatility and risk, requires extensive research, many projects may fail, ' \
          'regulatory uncertainty for newer tokens.'
        ]
        criteria = 'Cryptocurrency investment strategy for conservative investor seeking ' \
                   'portfolio diversification with moderate risk tolerance and long-term horizon'
        result = ActiveGenie::Comparator.by_debate(
          approaches[0],
          approaches[1],
          criteria
        )

        assert_equal approaches[0], result.data
      end
    end
  end
end
