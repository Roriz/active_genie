# frozen_string_literal: true

require_relative '../providers/unified_provider'
require_relative '../utils/text_case'
require_relative '../utils/logprobs_calculator'

module ActiveGenie
  module Scorer
    # The JuryBench class provides a foundation for Scorer text content against specified criteria
    # using AI-powered evaluation. It supports both single and multiple jury scenarios,
    # with the ability to automatically recommend juries when none are specified.
    #
    # The Scorer process evaluates text based on given criteria and returns detailed feedback
    # including individual jury scores, reasoning, and a final aggregated continuous score based on logprobs.
    #
    # @example JuryBench usage with a single jury
    #   JuryBench.call("Sample text", "Evaluate grammar and clarity", ["Grammar Expert"])
    #
    # @example Usage with automatic jury recommendation
    #   JuryBench.call("Sample text", "Evaluate technical accuracy")
    #
    class JuryBench < ActiveGenie::BaseModule
      # @param text [String] The text content to be evaluated
      # @param criteria [String] The evaluation criteria or rubric to assess against
      # @param juries [Array<String>] Optional list of specific juries. If empty,
      #   juries will be automatically recommended based on the content and criteria
      # @param config [Hash] Additional configuration config that modify the Scorer behavior
      # @return [ActiveGenie::Result] The evaluation result containing scores and reasoning
      def initialize(text, criteria, juries = [], config: {})
        @text = text
        @criteria = criteria
        @param_juries = Array(juries).compact.uniq
        super(config:)
      end

      def call
        messages = [
          { role: 'system', content: PROMPT },
          { role: 'user', content: "Scorer criteria: #{@criteria}" },
          { role: 'user', content: "Text to score: #{@text}" }
        ]

        provider_response = ::ActiveGenie::Providers::UnifiedProvider.function_calling(
          messages,
          build_function,
          config:,
          logprobs: true
        )

        response_formatted(provider_response)
      end

      PROMPT = File.read(File.join(__dir__, 'jury_bench.prompt.md'))

      # Longest suffix appended to a jury key when building schema properties.
      JURY_KEY_SUFFIX = '_reasoning'

      private

      def response_formatted(provider_response)
        data = extract_data(provider_response)
        logprobs_result = extract_logprobs(provider_response)

        final_score_val, logprob_metadata = calculate_final_score(data, logprobs_result)
        reasoning = data&.dig('final_reasoning')
        combined_metadata = (data || {}).merge(logprob_metadata)

        ActiveGenie::Result.new(
          data: final_score_val,
          reasoning:,
          metadata: combined_metadata
        )
      end

      def extract_data(provider_response)
        if provider_response.is_a?(Hash) && provider_response.key?(:data)
          provider_response[:data]
        else
          provider_response
        end
      end

      def extract_logprobs(provider_response)
        provider_response.is_a?(Hash) ? provider_response[:logprobs] : nil
      end

      def calculate_final_score(data, logprobs_result)
        fallback_score = data&.dig('final_score') || data&.dig(:final_score) || 0
        return [fallback_score, {}] if logprobs_result.nil?

        final_score_cands = ActiveGenie::Utils::LogprobsCalculator.extract_field_candidates(
          logprobs_result, 'final_score'
        )
        final_score_calc = ActiveGenie::Utils::LogprobsCalculator.calculate_continuous_score(
          final_score_cands, min_score: 0.0, max_score: 100.0
        )

        jury_expected_values = compute_jury_expected_values(logprobs_result)
        aggregated_jury_reward = ActiveGenie::Utils::LogprobsCalculator.aggregate_expected_rewards(
          jury_expected_values, min_score: 0.0, max_score: 100.0
        )

        chosen_score = final_score_calc&.expected_value || aggregated_jury_reward&.raw_expected_reward || fallback_score
        logprob_metadata = build_logprob_metadata(final_score_calc, aggregated_jury_reward, chosen_score)

        [chosen_score, logprob_metadata]
      end

      def compute_jury_expected_values(logprobs_result)
        juries.filter_map do |jury|
          jury_key = jury_key_for(jury)
          cands = ActiveGenie::Utils::LogprobsCalculator.extract_field_candidates(logprobs_result, "#{jury_key}_score")
          calc = ActiveGenie::Utils::LogprobsCalculator.calculate_continuous_score(cands, min_score: 0.0, max_score: 100.0)
          calc&.expected_value
        end
      end

      def build_logprob_metadata(final_score_calc, aggregated_jury_reward, chosen_score)
        meta = { 'logprobs_used' => true, 'continuous_final_score' => chosen_score }
        meta['final_score_expected_value'] = final_score_calc.expected_value if final_score_calc
        meta['final_score_normalized'] = final_score_calc.normalized_score if final_score_calc

        if aggregated_jury_reward
          meta['juries_raw_expected_reward'] = aggregated_jury_reward.raw_expected_reward
          meta['juries_normalized_score'] = aggregated_jury_reward.normalized_score
        end

        meta
      end

      def build_function
        {
          name: 'scorer',
          description: 'Score the text based on the given criteria.',
          parameters: {
            type: 'object',
            properties: properties,
            required: properties.keys
          }
        }
      end

      def properties
        @properties ||= begin
          tmp = {}
          juries.each do |jury|
            jury_key = jury_key_for(jury)
            tmp["#{jury_key}_reasoning"] = {
              type: 'string',
              description: "The reasoning of the Scorer process by #{jury}."
            }
            tmp["#{jury_key}_score"] = {
              type: 'number',
              description: "The score given by #{jury}.",
              min: 0,
              max: 100
            }
          end

          tmp[:final_score] = {
            type: 'number',
            description: 'The final score based on the previous juries'
          }
          tmp[:final_reasoning] = {
            type: 'string',
            description: 'The final reasoning based on the previous juries'
          }

          tmp
        end
      end

      # Jury names become JSON schema property keys, which providers cap at 64
      # characters. Reserve room for the suffix so the combined key still fits.
      def jury_key_for(jury)
        ActiveGenie::TextCase.underscore(
          jury,
          max_length: ActiveGenie::TextCase::MAX_KEY_LENGTH - JURY_KEY_SUFFIX.length
        )
      end

      def juries
        @juries ||= if @param_juries.any?
                      @param_juries
                    else
                      ::ActiveGenie::Lister::Juries.call(@text, @criteria, config:).data
                    end
      end

      def module_config
        { llm: { recommended_model: 'deepseek-chat' } }
      end
    end
  end
end
