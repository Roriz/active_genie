# frozen_string_literal: true

require_relative "../../test_helper"

SIMPLE_TESTS = [
  { input: ["Roriz is 25 years old", { name: { type: 'string' }, age: { type: 'integer' } }], expected: { name: 'Roriz', age: 25 } },
  { input: ["Nike Air Max 90 - Size 42 - $199.99", { brand: { type: 'string' }, price: { type: 'number' }, currency: { type: 'string' }, size: { type: 'integer' } }], expected: { brand: 'Nike', price: 199.99, currency: 'USD', size: 42 } },
  { input: ["Available in stock: 15 units of iPhone 14 Pro Max 256GB in Space Gray", 
    { model: { type: 'string', description: 'Comercial name of the product' }, storage: { type: 'integer' }, color: { type: 'string' }, stock: { type: 'integer' } }],
    expected: { model: 'iPhone 14 Pro Max', storage: 256, color: 'Space Gray', stock: 15 }
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
  { input: ["2022 Tesla Model 3 Long Range, Electric, 15,000 miles, Autopilot included. Listed at $45,995",
    { year: { type: 'integer' }, make: { type: 'string' }, model: { type: 'string' }, mileage: { type: 'integer' }, price: { type: 'number' } }],
    expected: { year: 2022, make: 'Tesla', model: 'Model 3 Long Range', mileage: 15000, price: 45995 }
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

class ActiveGenie::DataExtractor::BasicTest < Minitest::Test
  def test_simple_extraction
    SIMPLE_TESTS.each do |test|
      result = ActiveGenie::DataExtractor::Basic.call(*test[:input])

      test[:expected].each do |key, value|
        assert result.key?(key.to_s), "Missing key: #{key}, result: #{result.to_s[0..100]}"
        print('.')
        assert_equal value, result[key.to_s]
        print('.')
      end
    end
  end
end