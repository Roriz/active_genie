# frozen_string_literal: true

require_relative '../test_helper'

module ActiveGenie
  module Lister
    class FeudTest < Minitest::Test
      def test_feud_most_likely_to_be_affected_by_climate_change
        result = ActiveGenie::Lister.with_feud(
          'Industries that are most likely to be affected by climate change'
        )
        result = result.map(&:downcase)

        assert_includes result, 'Agriculture', "Agriculture should be in the list, full result: #{result}"
        assert_includes result, 'Energy', "Energy should be in the list, full result: #{result}"
        assert_includes result, 'Tourism', "Tourism should be in the list, full result: #{result}"
      end

      # Food and Dining Tests
      def test_feud_favorite_fast_foods
        result = ActiveGenie::Lister.with_feud(
          'Favorite fast foods'
        )
        result = result.map(&:downcase)

        assert_includes result, 'Pizza', "Pizza should be in the list, full result: #{result}"
        assert_includes result, 'Hamburgers', "Hamburgers should be in the list, full result: #{result}"
      end

      def test_feud_breakfast_foods
        result = ActiveGenie::Lister.with_feud(
          'Most popular american breakfast foods'
        )
        result = result.map(&:downcase)

        breakfast_items = ['Eggs', 'Toast', 'Cereal', 'Pancakes', 'Bacon', 'Coffee']
        assert breakfast_items.any? { |item| result.include?(item.downcase) }, 
               "Should include at least one common breakfast item, full result: #{result}"
      end

      def test_feud_comfort_foods_winter
        result = ActiveGenie::Lister.with_feud(
          'Comfort foods people crave during winter'
        )
        result = result.map(&:downcase)

        comfort_foods = ['Soup', 'Hot chocolate', 'Stew', 'Chili', 'Mac and cheese']
        assert comfort_foods.any? { |item| result.include?(item.downcase) }, 
               "Should include at least one winter comfort food, full result: #{result}"
      end

      # Consumer Behavior Tests
      def test_feud_smartphone_buying_factors
        result = ActiveGenie::Lister.with_feud(
          'Factors consumers consider when buying a smartphone'
        )
        result = result.map(&:downcase)

        assert_includes result, 'Price', "Price should be in the list, full result: #{result}"
        buying_factors = ['Battery life', 'Camera quality', 'Storage', 'Brand']
        assert buying_factors.any? { |factor| result.include?(factor.downcase) }, 
               "Should include common buying factors, full result: #{result}"
      end

      def test_feud_online_shopping_reasons
        result = ActiveGenie::Lister.with_feud(
          'Reasons people prefer online shopping over in-store shopping'
        )
        result = result.map(&:downcase)

        shopping_reasons = ['Convenience', 'Better prices', 'No crowds', 'Save time', 'More selection']
        assert shopping_reasons.any? { |reason| result.include?(reason.downcase) }, 
               "Should include common online shopping reasons, full result: #{result}"
      end

      # Entertainment and Media Tests
      def test_feud_streaming_services
        result = ActiveGenie::Lister.with_feud(
          'Most popular streaming services'
        )
        result = result.map(&:downcase)

        streaming_services = ['Netflix', 'YouTube', 'Disney+', 'Amazon Prime', 'Hulu']
        assert streaming_services.any? { |service| result.include?(service.downcase) }, 
               "Should include popular streaming services, full result: #{result}"
      end

      def test_feud_movie_genres
        result = ActiveGenie::Lister.with_feud(
          'Most popular movie genres'
        )
        result = result.map(&:downcase)

        movie_genres = ['Action', 'Comedy', 'Drama', 'Horror', 'Romance']
        assert movie_genres.any? { |genre| result.include?(genre.downcase) }, 
               "Should include popular movie genres, full result: #{result}"
      end

      # Work and Career Tests
      def test_feud_job_interview_questions
        result = ActiveGenie::Lister.with_feud(
          'Most common job interview questions'
        )
        result = result.map(&:downcase)

        interview_questions = ['Tell me about yourself', 'Why do you want this job', 'What are your strengths', 'What are your weaknesses', 'Where do you see yourself']
        assert interview_questions.any? { |question| result.any? { |r| r.downcase.include?(question.downcase.split(' ').first) } }, 
               "Should include common interview question patterns, full result: #{result}"
      end

      def test_feud_workplace_benefits
        result = ActiveGenie::Lister.with_feud(
          'Most valued employee benefits'
        )
        result = result.map(&:downcase)

        benefits = ['Health insurance', 'Vacation time', 'Retirement plan', 'Flexible schedule', 'Remote work']
        assert benefits.any? { |benefit| result.include?(benefit.downcase) }, 
               "Should include valued employee benefits, full result: #{result}"
      end

      # Lifestyle and Personal Tests
      def test_feud_new_years_resolutions
        result = ActiveGenie::Lister.with_feud(
          'Most common New Year resolutions'
        )
        result = result.map(&:downcase)

        resolutions = ['Lose weight', 'Exercise more', 'Eat healthier', 'Save money', 'Quit smoking']
        assert resolutions.any? { |resolution| result.include?(resolution.downcase) }, 
               "Should include common New Year resolutions, full result: #{result}"
      end

      def test_feud_weekend_activities
        result = ActiveGenie::Lister.with_feud(
          'Things people like to do on weekends'
        )
        result = result.map(&:downcase)

        weekend_activities = ['Sleep in', 'Spend time with family', 'Watch movies', 'Go out to eat', 'Exercise']
        assert weekend_activities.any? { |activity| result.include?(activity.downcase) }, 
               "Should include popular weekend activities, full result: #{result}"
      end

      def test_feud_stress_relief_methods
        result = ActiveGenie::Lister.with_feud(
          'Ways people relieve stress'
        )
        result = result.map(&:downcase)

        stress_relief = ['Exercise', 'Listen to music', 'Sleep', 'Talk to friends', 'Watch TV']
        assert stress_relief.any? { |method| result.include?(method.downcase) }, 
               "Should include common stress relief methods, full result: #{result}"
      end

      # Technology and Social Media Tests
      def test_feud_social_media_platforms
        result = ActiveGenie::Lister.with_feud(
          'Most popular social media platforms'
        )
        result = result.map(&:downcase)

        social_platforms = ['Facebook', 'Instagram', 'Twitter', 'TikTok', 'YouTube']
        assert social_platforms.any? { |platform| result.include?(platform.downcase) }, 
               "Should include popular social media platforms, full result: #{result}"
      end

      # Travel and Transportation Tests
      def test_feud_travel_packing_items
        result = ActiveGenie::Lister.with_feud(
          'Things people always forget to pack when traveling'
        )
        result = result.map(&:downcase)

        forgotten_items = ['Phone charger', 'Toothbrush', 'Underwear', 'Medications', 'Sunglasses']
        assert forgotten_items.any? { |item| result.include?(item.downcase) }, 
               "Should include commonly forgotten travel items, full result: #{result}"
      end

      # Health and Fitness Tests
      def test_feud_exercise_types
        result = ActiveGenie::Lister.with_feud(
          'Most popular types of exercise'
        )
        result = result.map(&:downcase)

        exercise_types = ['Walking', 'Running', 'Swimming', 'Cycling', 'Weight lifting']
        assert exercise_types.any? { |exercise| result.include?(exercise.downcase) }, 
               "Should include popular exercise types, full result: #{result}"
      end

      def test_feud_diet_motivations
        result = ActiveGenie::Lister.with_feud(
          'Reasons people go on diets'
        )
        result = result.map(&:downcase)

        diet_reasons = ['Lose weight', 'Get healthy', 'Look better', 'Feel better', 'Doctor advice']
        assert diet_reasons.any? { |reason| result.include?(reason.downcase) }, 
               "Should include common diet motivations, full result: #{result}"
      end

      # Education and Learning Tests
      def test_feud_study_problems
        result = ActiveGenie::Lister.with_feud(
          'Common problems students face when studying'
        )
        result = result.map(&:downcase)

        study_problems = ['Procrastination', 'Distractions', 'Time management', 'Understanding material', 'Motivation']
        assert study_problems.any? { |problem| result.include?(problem.downcase) }, 
               "Should include common study problems, full result: #{result}"
      end

      def test_feud_parenting_challenges
        result = ActiveGenie::Lister.with_feud(
          'Biggest challenges of parenting'
        )
        result = result.map(&:downcase)

        parenting_challenges = ['Lack of sleep', 'Time management', 'Discipline', 'Money', 'Patience']
        assert parenting_challenges.any? { |challenge| result.include?(challenge.downcase) }, 
               "Should include common parenting challenges, full result: #{result}"
      end

      # Home and Household Tests
      def test_feud_household_chores
        result = ActiveGenie::Lister.with_feud(
          'Most hated household chores'
        )
        result = result.map(&:downcase)

        chores = ['Dishes', 'Cleaning bathrooms', 'Laundry', 'Vacuuming', 'Taking out trash']
        assert chores.any? { |chore| result.include?(chore.downcase) }, 
               "Should include commonly disliked chores, full result: #{result}"
      end

      def test_feud_home_improvement_projects
        result = ActiveGenie::Lister.with_feud(
          'Most popular home improvement projects'
        )
        result = result.map(&:downcase)

        projects = ['Painting', 'Kitchen remodel', 'Bathroom remodel', 'Landscaping', 'Flooring']
        assert projects.any? { |project| result.include?(project.downcase) }, 
               "Should include popular home improvement projects, full result: #{result}"
      end

      # Seasonal and Holiday Tests
      def test_feud_christmas_gifts
        result = ActiveGenie::Lister.with_feud(
          'Most popular Christmas gifts'
        )
        result = result.map(&:downcase)

        christmas_gifts = ['Clothes', 'Electronics', 'Toys', 'Gift cards', 'Books']
        assert christmas_gifts.any? { |gift| result.include?(gift.downcase) }, 
               "Should include popular Christmas gifts, full result: #{result}"
      end

      # Configuration and Edge Cases Tests
      def test_feud_with_custom_item_count_3
        result = ActiveGenie::Lister.with_feud(
          'Most popular pets',
        )
        result = result.map(&:downcase)

        pets = ['Dogs', 'Cats', 'Fish', 'Birds']
        assert pets.any? { |pet| result.include?(pet.downcase) }, 
               "Should include popular pets, full result: #{result}"
      end

      def test_feud_complex_theme
        result = ActiveGenie::Lister.with_feud(
          'Things that make people feel old when they realize younger generations do not know about them'
        )
        result = result.map(&:downcase)

        old_things = ['VHS tapes', 'Dial-up internet', 'Pay phones', 'CD players', 'Blockbuster']
        assert old_things.any? { |thing| result.include?(thing.downcase) }, 
               "Should include things that make people feel old, full result: #{result}"
      end

      def test_feud_returns_array_of_strings
        result = ActiveGenie::Lister.with_feud(
          'Most annoying things about modern technology'
        )
        result = result.map(&:downcase)

        assert_instance_of Array, result
        assert result.all? { |item| item.is_a?(String) }, "All items should be strings"
        assert result.all? { |item| !item.empty? }, "No items should be empty strings"
      end

      def test_feud_consistent_results_length
        theme = 'Reasons people are late to work'
        
        result1 = ActiveGenie::Lister.with_feud(theme)
        result2 = ActiveGenie::Lister.with_feud(theme)
        
        assert_equal result1.length, result2.length, "Results should have consistent length"
        assert_equal 5, result1.length, "Should return default 5 items"
      end

      # Business and Professional Tests
      def test_feud_startup_failure_reasons
        result = ActiveGenie::Lister.with_feud(
          'Common reasons why startups fail'
        )
        result = result.map(&:downcase)

        failure_reasons = ['No market need', 'Ran out of cash', 'Not the right team', 'Competition', 'Poor marketing']
        assert failure_reasons.any? { |reason| result.include?(reason.downcase) }, 
               "Should include common startup failure reasons, full result: #{result}"
      end

      def test_feud_office_pet_peeves
        result = ActiveGenie::Lister.with_feud(
          'Things that annoy people most in the workplace'
        )
        result = result.map(&:downcase)

        pet_peeves = ['Loud talking', 'Micromanagement', 'Poor communication', 'Meeting overload', 'Messy common areas']
        assert pet_peeves.any? { |peeve| result.include?(peeve.downcase) }, 
               "Should include common office annoyances, full result: #{result}"
      end

      def test_feud_networking_tips
        result = ActiveGenie::Lister.with_feud(
          'Best ways to network professionally'
        )
        result = result.map(&:downcase)

        networking_tips = ['Attend industry events', 'Use LinkedIn', 'Ask for referrals', 'Join professional groups', 'Follow up']
        assert networking_tips.any? { |tip| result.include?(tip.downcase) }, 
               "Should include effective networking strategies, full result: #{result}"
      end

      def test_feud_meeting_problems
        result = ActiveGenie::Lister.with_feud(
          'What makes meetings ineffective'
        )
        result = result.map(&:downcase)

        meeting_issues = ['No clear agenda', 'Too many people', 'Off-topic discussions', 'Too long', 'No follow-up']
        assert meeting_issues.any? { |issue| result.include?(issue.downcase) }, 
               "Should include common meeting problems, full result: #{result}"
      end

      # Technology and Digital Life Tests
      def test_feud_video_call_problems
        result = ActiveGenie::Lister.with_feud(
          'Most common problems during video calls'
        )
        result = result.map(&:downcase)

        video_problems = ['Bad internet connection', 'Audio issues', 'Camera not working', 'Background noise', 'Frozen screen']
        assert video_problems.any? { |problem| result.include?(problem.downcase) }, 
               "Should include common video call issues, full result: #{result}"
      end

      # Financial and Economic Tests
      def test_feud_budgeting_challenges
        result = ActiveGenie::Lister.with_feud(
          'Biggest challenges people face when trying to budget'
        )
        result = result.map(&:downcase)

        budget_challenges = ['Unexpected expenses', 'Low income', 'Lack of discipline', 'Too complicated', 'Emergency fund']
        assert budget_challenges.any? { |challenge| result.include?(challenge.downcase) }, 
               "Should include common budgeting challenges, full result: #{result}"
      end

      def test_feud_investment_fears
        result = ActiveGenie::Lister.with_feud(
          'Reasons people are afraid to start investing'
        )
        result = result.map(&:downcase)

        investment_fears = ['Fear of losing money', 'Too complicated', 'Not enough money', 'Don\'t know where to start', 'Market volatility']
        assert investment_fears.any? { |fear| result.include?(fear.downcase) }, 
               "Should include common investment fears, full result: #{result}"
      end

      def test_feud_debt_sources
        result = ActiveGenie::Lister.with_feud(
          'Most common sources of debt for young adults'
        )
        result = result.map(&:downcase)

        debt_sources = ['Student loans', 'Credit cards', 'Car loans', 'Medical bills', 'Housing costs']
        assert debt_sources.any? { |source| result.include?(source.downcase) }, 
               "Should include common debt sources, full result: #{result}"
      end

      def test_feud_financial_goals
        result = ActiveGenie::Lister.with_feud(
          'Top financial goals people want to achieve'
        )
        result = result.map(&:downcase)

        financial_goals = ['Emergency fund', 'Buy a house', 'Retire comfortably', 'Pay off debt', 'Start investing']
        assert financial_goals.any? { |goal| result.include?(goal.downcase) }, 
               "Should include common financial goals, full result: #{result}"
      end

      # Health and Wellness Tests
      def test_feud_mental_health_activities
        result = ActiveGenie::Lister.with_feud(
          'Activities that help improve mental health'
        )
        result = result.map(&:downcase)

        mental_health_activities = ['Exercise', 'Meditation', 'Talking to friends', 'Getting enough sleep', 'Spending time outdoors']
        assert mental_health_activities.any? { |activity| result.include?(activity.downcase) }, 
               "Should include mental health activities, full result: #{result}"
      end

      # Social and Cultural Tests
      def test_feud_social_media_problems
        result = ActiveGenie::Lister.with_feud(
          'Negative effects of social media on society'
        )
        result = result.map(&:downcase)

        social_problems = ['Cyberbullying', 'Misinformation', 'Addiction', 'Privacy concerns', 'Comparison culture']
        assert social_problems.any? { |problem| result.include?(problem.downcase) }, 
               "Should include social media problems, full result: #{result}"
      end

      def test_feud_community_problems
        result = ActiveGenie::Lister.with_feud(
          'Biggest problems facing local communities'
        )
        result = result.map(&:downcase)

        community_problems = ['Crime', 'Traffic', 'Lack of affordable housing', 'Poor schools', 'Economic inequality']
        assert community_problems.any? { |problem| result.include?(problem.downcase) }, 
               "Should include common community problems, full result: #{result}"
      end

      # Environmental and Sustainability Tests
      def test_feud_climate_change_actions
        result = ActiveGenie::Lister.with_feud(
          'Things individuals can do to help fight climate change'
        )
        result = result.map(&:downcase)

        climate_actions = ['Reduce energy use', 'Use public transportation', 'Recycle', 'Eat less meat', 'Buy sustainable products']
        assert climate_actions.any? { |action| result.include?(action.downcase) }, 
               "Should include climate change actions, full result: #{result}"
      end

      def test_feud_plastic_pollution_sources
        result = ActiveGenie::Lister.with_feud(
          'Biggest sources of plastic pollution'
        )
        result = result.map(&:downcase)

        pollution_sources = ['Single-use bags', 'Water bottles', 'Food packaging', 'Straws', 'Microplastics']
        assert pollution_sources.any? { |source| result.include?(source.downcase) }, 
               "Should include plastic pollution sources, full result: #{result}"
      end

      def test_feud_sustainable_living_barriers
        result = ActiveGenie::Lister.with_feud(
          'Barriers that prevent people from living more sustainably'
        )
        result = result.map(&:downcase)

        sustainability_barriers = ['Cost', 'Convenience', 'Lack of options', 'Time constraints', 'Lack of knowledge']
        assert sustainability_barriers.any? { |barrier| result.include?(barrier.downcase) }, 
               "Should include sustainability barriers, full result: #{result}"
      end

      # Education and Learning Tests
      def test_feud_student_stress_sources
        result = ActiveGenie::Lister.with_feud(
          'Biggest sources of stress for college students'
        )
        result = result.map(&:downcase)

        stress_sources = ['Financial pressure', 'Academic workload', 'Career uncertainty', 'Social pressure', 'Time management']
        assert stress_sources.any? { |source| result.include?(source.downcase) }, 
               "Should include student stress sources, full result: #{result}"
      end

      def test_feud_online_learning_challenges
        result = ActiveGenie::Lister.with_feud(
          'Challenges students face with online learning'
        )
        result = result.map(&:downcase)

        online_challenges = ['Lack of interaction', 'Technical issues', 'Distractions at home', 'Self-motivation', 'Time zone differences']
        assert online_challenges.any? { |challenge| result.include?(challenge.downcase) }, 
               "Should include online learning challenges, full result: #{result}"
      end

      def test_feud_study_habits_effective
        result = ActiveGenie::Lister.with_feud(
          'Most effective study habits for academic success'
        )
        result = result.map(&:downcase)

        study_habits = ['Regular schedule', 'Take breaks', 'Active note-taking', 'Practice tests', 'Eliminate distractions']
        assert study_habits.any? { |habit| result.include?(habit.downcase) }, 
               "Should include effective study habits, full result: #{result}"
      end

      # Transportation and Urban Life Tests
      def test_feud_commuting_frustrations
        result = ActiveGenie::Lister.with_feud(
          'Most frustrating aspects of daily commuting'
        )
        result = result.map(&:downcase)

        commute_frustrations = ['Traffic jams', 'Public transport delays', 'High costs', 'Crowded trains', 'Parking problems']
        assert commute_frustrations.any? { |frustration| result.include?(frustration.downcase) }, 
               "Should include commuting frustrations, full result: #{result}"
      end

      def test_feud_car_buying_factors
        result = ActiveGenie::Lister.with_feud(
          'Most important factors when buying a car'
        )
        result = result.map(&:downcase)

        car_factors = ['Price', 'Fuel efficiency', 'Reliability', 'Safety ratings', 'Resale value']
        assert car_factors.any? { |factor| result.include?(factor.downcase) }, 
               "Should include car buying factors, full result: #{result}"
      end

      def test_feud_public_transport_improvements
        result = ActiveGenie::Lister.with_feud(
          'Ways to improve public transportation'
        )
        result = result.map(&:downcase)

        transport_improvements = ['More frequent service', 'Better cleanliness', 'Lower costs', 'Real-time updates', 'More routes']
        assert transport_improvements.any? { |improvement| result.include?(improvement.downcase) }, 
               "Should include public transport improvements, full result: #{result}"
      end

      def test_feud_city_living_downsides
        result = ActiveGenie::Lister.with_feud(
          'Worst things about living in a big city'
        )
        result = result.map(&:downcase)

        city_downsides = ['High cost of living', 'Traffic', 'Noise', 'Crowding', 'Pollution']
        assert city_downsides.any? { |downside| result.include?(downside.downcase) }, 
               "Should include city living downsides, full result: #{result}"
      end

      # Retail and Shopping Tests
      def test_feud_shopping_deal_breakers
        result = ActiveGenie::Lister.with_feud(
          'Things that make customers not want to shop at a store'
        )
        result = result.map(&:downcase)

        deal_breakers = ['Poor customer service', 'High prices', 'Long wait times', 'Messy store', 'Limited selection']
        assert deal_breakers.any? { |breaker| result.include?(breaker.downcase) }, 
               "Should include shopping deal breakers, full result: #{result}"
      end

      def test_feud_impulse_buying_triggers
        result = ActiveGenie::Lister.with_feud(
          'Things that trigger impulse buying'
        )
        result = result.map(&:downcase)

        buying_triggers = ['Sales and discounts', 'Emotional state', 'Limited time offers', 'Product placement', 'Social influence']
        assert buying_triggers.any? { |trigger| result.include?(trigger.downcase) }, 
               "Should include impulse buying triggers, full result: #{result}"
      end

      def test_feud_customer_service_expectations
        result = ActiveGenie::Lister.with_feud(
          'What customers expect from good customer service'
        )
        result = result.map(&:downcase)

        service_expectations = ['Quick response', 'Friendly staff', 'Problem resolution', 'Knowledge', 'Follow-up']
        assert service_expectations.any? { |expectation| result.include?(expectation.downcase) }, 
               "Should include customer service expectations, full result: #{result}"
      end

      # Custom Configuration Tests with Different Juries
      def test_feud_with_small_list_politics
        result = ActiveGenie::Lister.with_feud(
          'Most controversial political topics',
        )
        result = result.map(&:downcase)

        political_topics = ['Healthcare', 'Immigration', 'Gun control', 'Taxes', 'Education']
        assert political_topics.any? { |topic| result.include?(topic.downcase) }, 
               "Should include controversial political topics, full result: #{result}"
      end

      def test_feud_productivity_killers
        result = ActiveGenie::Lister.with_feud(
          'Biggest productivity killers in the modern workplace'
        )
        result = result.map(&:downcase)

        productivity_killers = ['Constant notifications', 'Unnecessary meetings', 'Email overload', 'Open office distractions', 'Multitasking']
        assert productivity_killers.any? { |killer| result.include?(killer.downcase) }, 
               "Should include productivity killers, full result: #{result}"
      end
    end
  end
end
