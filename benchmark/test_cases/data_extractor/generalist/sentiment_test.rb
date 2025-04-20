# frozen_string_literal: true

require_relative "../../test_helper"

class ActiveGenie::DataExtractor::PreciseTest < Minitest::Test
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

    result = ActiveGenie::DataExtractor.call(thread_messages, data_to_extract)

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

    result = ActiveGenie::DataExtractor.call(job_description, data_to_extract)

    assert_equal result['need_graduation'], true
    assert_equal result['required_minimal_years_of_experience'], 1
    assert_equal result['discipline'], 'Marketing'
  end
end