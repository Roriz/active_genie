# frozen_string_literal: true

# Builds extractor.with_litote test cases from CondaQA (Apache-2.0, see NOTICE.md in this folder):
# passages whose meaning hinges on a negation cue, with a yes / no question; "don't know" becomes
# absent gold (the extractor answers null when the text does not say).
#
#   bundle exec ruby eval/sources/condaqa/build.rb
#
# Downloads the test split at a pinned commit into tmp/datasets/condaqa (gitignored), checks its
# SHA-256, and picks PER_LABEL questions per answer from distinct passages in a stable hash order.

require_relative '../../lib/genie_eval'

module CondaqaSource
  URL = 'https://huggingface.co/datasets/lasha-nlp/CONDAQA/resolve/3c9caa2f2f6960711e7f4d2e800581def2b6c183/test.json'
  SHA256 = 'ffd7f4ad85689b2317283430a226cd759c3ccc40070e6a32652e7ae84ae90e8e'
  FILE = File.join(GenieEval::REPO, 'tmp', 'datasets', 'condaqa', 'test.json')
  CELL = 'extractor.with_litote'
  PER_LABEL = { 'YES' => 6, 'NO' => 6, "DON'T KNOW" => 3 }.freeze
  ANSWERS = { 'YES' => 'yes', 'NO' => 'no', "DON'T KNOW" => nil }.freeze # nil: the passage does not say
  MAX_CHARS = 1500

  module_function

  def run
    download unless File.exist?(FILE)
    raise "#{FILE}: SHA-256 mismatch, refusing to use it" unless Digest::SHA256.file(FILE).hexdigest == SHA256

    rows = File.readlines(FILE).map { |line| JSON.parse(line) }
    picked = pick(rows)
    write(picked)
    puts "#{CELL}: #{picked.size} CondaQA questions written to the test pool"
  end

  def download
    FileUtils.mkdir_p(File.dirname(FILE))
    system('curl', '-sSL', '-o', FILE, URL, exception: true)
  end

  def pick(rows)
    eligible = rows.select { |r| ANSWERS.key?(r['label']) && r['sentence1'].size <= MAX_CHARS }
                   .sort_by { |r| Digest::SHA256.hexdigest(r['SampleID'].to_s) }
    used = {}
    PER_LABEL.flat_map do |label, count|
      eligible.select { |r| r['label'] == label }.each_with_object([]) do |row, out|
        next if used[row['PassageID']] || out.size >= count

        used[row['PassageID']] = true
        out << row
      end
    end
  end

  def write(picked)
    cases = picked.map do |r|
      description = "#{r['sentence2']} Answer yes or no. Null if the passage does not say."
      schema = { 'answer' => { 'type' => 'string', 'enum' => %w[yes no], 'description' => description } }
      { 'id' => case_id(r), 'cell' => CELL, 'source' => 'condaqa',
        'tags' => { 'domain' => 'general', 'difficulty' => 'adversarial', 'negation_cue' => r['original cue'] },
        'input' => { 'text' => r['sentence1'], 'schema' => schema } }
    end
    gold = picked.map do |r|
      { 'id' => case_id(r), 'gold' => { 'fields' => { 'answer' => answer_gold(ANSWERS.fetch(r['label'])) } },
        'why' => "CondaQA crowd label #{r['label']} for a passage that hinges on the negation cue " \
                 "\"#{r['original cue']}\".",
        'labeled_by' => 'condaqa' }
    end
    GenieEval::Store.replace_cases(CELL, cases, gold) { |id| id.start_with?('condaqa_') }
  end

  def answer_gold(answer)
    answer ? { 'present' => true, 'check' => 'eq', 'value' => answer } : { 'present' => false }
  end

  def case_id(row)
    "condaqa_#{row['SampleID']}"
  end
end

CondaqaSource.run if $PROGRAM_NAME == __FILE__
