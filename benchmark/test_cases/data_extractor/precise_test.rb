# frozen_string_literal: true

require_relative "../test_helper"

class ActiveGenie::DataExtractor::PreciseTest < Minitest::Test
  TESTS = [
    { input: ["Roriz is 25 years old", { name: { type: 'string' }, age: { type: 'integer' } }], expected: { name: 'Roriz', age: 25 } },
    { input: ["Nike Air Max 90 - Size 42 - $199.99", { brand: { type: 'string' }, price: { type: 'number' }, currency: { type: 'string' }, size: { type: 'integer' } }], expected: { brand: 'Nike', price: 199.99, currency: 'USD', size: 42 } },
    { input: ["Available in stock: 15 units of iPhone 14 Pro Max in Space Gray", 
      { model: { type: 'string', description: 'Comercial name of the product' },  color: { type: 'string' }, stock: { type: 'integer' } }],
      expected: { model: 'iPhone 14 Pro Max', color: 'Space Gray', stock: 15 }
    },
    { input: ["4.5 stars - Amazing sushi restaurant with great service. Average wait time: 30 minutes",
      { rating: { type: 'number' }, cuisine: { type: 'string' }, wait_time: { type: 'integer' } }],
      expected: { rating: 4.5, cuisine: 'sushi', wait_time: 30 }
    },
    { input: ["Current temperature in New York is -5°C with 75% humidity and light snow",
      { city: { type: 'string' }, temperature: { type: 'integer' }, humidity: { type: 'integer' }, conditions: { type: 'string' } }],
      expected: { city: 'New York', temperature: -5, humidity: 75, conditions: 'light snow' }
    },
    { input: ["Modern 3-bedroom apartment, 120m² with 2 bathrooms, located in Downtown. Monthly rent: $2,500",
      { bedrooms: { type: 'integer' }, area: { type: 'number' }, bathrooms: { type: 'integer' }, location: { type: 'string' }, rent: { type: 'number' } }],
      expected: { bedrooms: 3, area: 120, bathrooms: 2, location: 'Downtown', rent: 2500 }
    },
    { input: ["Senior Software Engineer position at Google - 5+ years experience required. Salary range: $150,000-$200,000/year",
      { company: { type: 'string' }, position: { type: 'string' }, min_experience: { type: 'integer' }, min_salary: { type: 'integer' }, max_salary: { type: 'integer' } }],
      expected: { company: 'Google', position: 'Senior Software Engineer', min_experience: 5, min_salary: 150000, max_salary: 200000 }
    },
    { input: ["Flight AA123 from LAX to JFK, departure at 10:30 AM, gate B12, duration: 5h 45m",
      { flight_number: { type: 'string' }, origin: { type: 'string' }, destination: { type: 'string' }, gate: { type: 'string' }, duration_minutes: { type: 'integer' } }],
      expected: { flight_number: 'AA123', origin: 'LAX', destination: 'JFK', gate: 'B12', duration_minutes: 345 }
    },
    { input: ["VIP ticket for Taylor Swift concert on March 15, 2024, at Madison Square Garden, Row A, Seat 12, Price: €250",
      { event: { type: 'string' }, venue: { type: 'string' }, iso_date: { type: 'string' }, row: { type: 'string' }, seat: { type: 'integer' }, price: { type: 'number' }, currency_ISO_4217: { type: 'string' } }],
      expected: { event: 'Taylor Swift concert', venue: 'Madison Square Garden', iso_date: '2024-03-15', row: 'A', seat: 12, price: 250, currency_ISO_4217: 'EUR' }
    },
    { input: ["2022 Tesla Model 3, Electric, 15,000 miles, Autopilot included. Listed at $45,995",
      { year: { type: 'integer' }, make: { type: 'string' }, model: { type: 'string' }, mileage: { type: 'integer' }, price: { type: 'number' } }],
      expected: { year: 2022, make: 'Tesla', model: 'Model 3', mileage: 15000, price: 45995 }
    },
    { input: ["Add 250g of organic whole wheat flour and 2.5 tsp of active dry yeast",
      { flour_amount: { type: 'number' }, flour_unit: { type: 'string' }, yeast_amount: { type: 'number' }, yeast_unit: { type: 'string' } }],
      expected: { flour_amount: 250, flour_unit: 'g', yeast_amount: 2.5, yeast_unit: 'tsp' }
    },
    { input: ["Final score: Lakers 112 - Warriors 108, MVP: LeBron James with 35 points and 12 assists",
      { winner: { type: 'string' }, winner_score: { type: 'integer' }, loser: { type: 'string' }, loser_score: { type: 'integer' }, mvp: { type: 'string' }, mvp_points: { type: 'integer' }, mvp_assists: { type: 'integer' } }],
      expected: { winner: 'Lakers', winner_score: 112, loser: 'Warriors', loser_score: 108, mvp: 'LeBron James', mvp_points: 35, mvp_assists: 12 }
    }
  ]

  TESTS.each_with_index do |test, index|
    define_method("test_#{test[:input][0].downcase.gsub(' ', '_').gsub('.', '')}_#{index}") do
      result = ActiveGenie::DataExtractor::Basic.call(*test[:input])

      test[:expected].each do |key, value|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        assert_equal value, result[key.to_s], "Expected #{value}, but was #{result[key.to_s]}"
      end
    end
  end

  def test_social_media_cat_thread_detector
    thread_messages = <<~THREAD
      Lily: Walked in on my cat staring at himself in the mirror like he was having a deep personal crisis. 😳
      Jake: Mine does that too! Probably wondering why he’s stuck with me instead of ruling a kingdom.
      Lily: He even touched the mirror like he was questioning reality. I think he unlocked a new level of self-awareness.
      Emma: My cat once saw his reflection, puffed up like a balloon, and threw paws at himself. He lost. Badly.
      Jake: Yep, mine tried to fight his reflection too. Then acted like he won. Bro, we all saw you get bodied.
    THREAD
    data_to_extract = {
      thread_subject: {
        type: 'string',
        enum: ['cat', 'dog', 'mouse', 'rabbit', 'hamster', 'guinea pig', 'ferret', 'chicken', 'goat', 'sheep', 'horse', 'cow', 'pig', 'other']
      },
      sentiment: {
        type: 'string',
        enum: ['positive', 'negative', 'neutral']
      }
    }

    result = ActiveGenie::DataExtractor::Precise.call(thread_messages, data_to_extract)

    assert_equal result['thread_subject'], 'cat'
    assert_equal result['sentiment'], 'positive'
  end

  def test_job_description_extractor
    job_description = <<~DESCRIPTION
      We are seeking a dynamic and detail-oriented Marketing Coordinator to join our team. The ideal candidate will contribute to various marketing initiatives, focusing on enhancing our brand presence and driving customer engagement.

      Key Responsibilities:
      Assist in the development and execution of marketing strategies and campaigns. Coordinate and manage content creation across various platforms, including social media, email, and website. Conduct market research to identify trends and insights for informed decision-making. Collaborate with design teams to produce promotional materials. Analyze the performance of marketing campaigns and generate reports. Maintain and update the marketing calendar. Support the organization and execution of events and trade shows. Manage relationships with vendors and partners to ensure timely delivery of services.

      Qualifications:
      Bachelor’s degree in Marketing, Communications, or a related field; 1-3 years of experience in a marketing role.; Strong understanding of digital marketing principles.; Excellent written and verbal communication skills.; Proficient in Microsoft Office Suite and familiarity with design software (e.g., Adobe Creative Suite) is a plus.; Strong organizational and project management skills.; Ability to work both independently and collaboratively within a team.

      Preferred Skills:
      Experience with CRM tools and email marketing software; Knowledge of SEO and web analytics tools (e.g., Google Analytics).; Creative problem-solving skills and attention to detail.

      Why Join Us?
      Opportunity to grow with a supportive and innovative team. Access to professional development and training opportunities. Competitive salary and benefits package. We are committed to fostering an inclusive and diverse work environment. Apply today to take your career to the next level!
    DESCRIPTION
    data_to_extract = {
      need_graduation: { type: 'boolean' },
      required_minimal_years_of_experience: { type: 'number' },
      discipline: { type: 'string', enum: ['Marketing', 'Engineering', 'Education'] },
    }

    result = ActiveGenie::DataExtractor::Precise.call(job_description, data_to_extract)

    assert_equal result['need_graduation'], true
    assert_equal result['required_minimal_years_of_experience'], 1
    assert_equal result['discipline'], 'Marketing'
  end
end