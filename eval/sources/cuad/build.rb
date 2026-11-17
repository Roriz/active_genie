# frozen_string_literal: true

# Builds the extractor.data test cases from CUAD v1 (CC BY 4.0, see NOTICE.md in this folder).
#
#   bundle exec ruby eval/sources/cuad/build.rb
#
# Downloads CUAD_v1.zip into tmp/datasets/cuad (gitignored), checks its pinned SHA-256, picks
# contracts of at most MAX_CHARS characters in a stable hash order, and writes their text, the
# 10-field schema and the gold from CUAD's normalized answers (master_clauses.csv). Re-running
# rewrites the same cases. A blank CUAD answer means the contract does not state it: gold "absent".

require 'csv'
require 'open3'
require_relative '../../lib/genie_eval'

module CuadSource
  # The CUAD fields this cell asks for, and how each maps to CUAD's answer columns.
  module Fields
    STRING_FIELDS = {
      'governing_law' => 'The state or country whose law governs the agreement. Null if the agreement does not say.',
      'agreement_date' => 'The date the agreement was signed or is dated. Null if not stated.',
      'effective_date' => 'The date the agreement takes effect. Null if not stated.',
      'expiration_date' => 'When the initial term ends: a date, or "perpetual". Null if not stated.',
      'renewal_term' => 'How the agreement renews after its initial term, e.g. "successive 1 year". ' \
                        'Null if it does not renew.'
    }.freeze

    BOOLEAN_FIELDS = {
      'has_non_compete' => 'Whether a party is restricted from competing with the other party ' \
                           'or operating in a market.',
      'has_exclusivity' => 'Whether a party must deal exclusively with the other party ' \
                           '(exclusive supply, license, territory, etc.).',
      'has_cap_on_liability' => 'Whether liability is capped or limited to an amount.',
      'has_audit_rights' => "Whether a party may audit the other party's books, records or operations.",
      'has_anti_assignment' => 'Whether assigning the agreement requires consent or notice, or is prohibited.'
    }.freeze

    SCHEMA = STRING_FIELDS.transform_values { |d| { 'type' => 'string', 'description' => d } }
                          .merge(BOOLEAN_FIELDS.transform_values { |d| { 'type' => 'boolean', 'description' => d } })
                          .freeze

    QUESTIONS = {
      'governing_law' => 'Which jurisdiction\'s law governs the agreement?',
      'agreement_date' => 'When was the agreement signed or dated?',
      'effective_date' => 'When does the agreement take effect?',
      'expiration_date' => 'When does the initial term of the agreement end?',
      'renewal_term' => 'How does the agreement renew after its initial term?'
    }.freeze

    # CUAD column for each boolean field.
    BOOLEANS = {
      'has_non_compete' => 'Non-Compete', 'has_exclusivity' => 'Exclusivity',
      'has_cap_on_liability' => 'Cap On Liability', 'has_audit_rights' => 'Audit Rights',
      'has_anti_assignment' => 'Anti-Assignment'
    }.freeze
  end
  include Fields

  URL = 'https://zenodo.org/api/records/4595826/files/CUAD_v1.zip/content'
  SHA256 = '88b694d99007d39777fa44cd72daf8297773d285dc3eab0091ba32078888d18e'
  DIR = File.join(GenieEval::REPO, 'tmp', 'datasets', 'cuad')
  CELL = 'extractor.data'
  COUNT = 30
  MAX_CHARS = 30_000

  module_function

  def run
    zip = File.join(DIR, 'CUAD_v1.zip')
    download(zip) unless File.exist?(zip)
    raise "#{zip}: SHA-256 mismatch, refusing to use it" unless Digest::SHA256.file(zip).hexdigest == SHA256

    extract(zip)
    rows = CSV.read(File.join(DIR, 'CUAD_v1', 'master_clauses.csv'), headers: true, encoding: 'bom|utf-8')
    picked = rows.filter_map { |row| candidate(row) }.sort_by { |c| Digest::SHA256.hexdigest(c[:stem]) }.first(COUNT)
    write(picked)
    puts "#{CELL}: #{picked.size} CUAD contracts written to the test pool"
  end

  def download(zip)
    FileUtils.mkdir_p(DIR)
    system('curl', '-sSL', '-o', zip, URL, exception: true)
  end

  def extract(zip)
    return if File.exist?(File.join(DIR, 'CUAD_v1', 'master_clauses.csv'))

    system('unzip', '-qo', zip, 'CUAD_v1/master_clauses.csv', 'CUAD_v1/full_contract_txt/*', '-d', DIR, exception: true)
  end

  def candidate(row)
    stem = File.basename(row['Filename'], '.pdf')
    file = File.join(DIR, 'CUAD_v1', 'full_contract_txt', "#{stem}.txt")
    return unless File.exist?(file)

    text = File.read(file, encoding: 'bom|utf-8').gsub(/[ \t]+\n/, "\n").strip
    return if text.size > MAX_CHARS

    { stem:, text:, row: }
  end

  def write(picked)
    cases = picked.map do |c|
      { 'id' => case_id(c[:stem]), 'cell' => CELL, 'source' => 'cuad',
        'tags' => { 'domain' => 'legal', 'difficulty' => nil, 'cuad_file' => "#{c[:stem]}.pdf" },
        'input' => { 'text' => c[:text], 'schema' => SCHEMA } }
    end
    gold = picked.map do |c|
      { 'id' => case_id(c[:stem]), 'gold' => { 'fields' => fields(c[:row]) },
        'why' => 'CUAD v1 normalized answers (lawyer-annotated); blank answers mean the contract does not state it.',
        'labeled_by' => 'cuad' }
    end
    GenieEval::Store.replace_cases(CELL, cases, gold) { |id| id.start_with?('cuad_') }
  end

  def case_id(stem)
    "cuad_#{stem.downcase.gsub(/[^a-z0-9]+/, '_')[0, 32].delete_suffix('_')}_#{Digest::SHA256.hexdigest(stem)[0, 6]}"
  end

  def fields(row)
    answer = ->(name) { row["#{name}-Answer"].to_s.strip }
    out = {
      'governing_law' => place(answer.call('Governing Law')),
      'agreement_date' => date_field('agreement_date', answer.call('Agreement Date')),
      'effective_date' => date_field('effective_date', answer.call('Effective Date')),
      'expiration_date' => date_field('expiration_date', answer.call('Expiration Date')),
      'renewal_term' => free_text('renewal_term', answer.call('Renewal Term'))
    }
    BOOLEANS.each do |field, column|
      out[field] = { 'present' => true, 'check' => 'eq', 'value' => answer.call(column) == 'Yes' }
    end
    out.compact
  end

  def place(value)
    return { 'present' => false } if value.empty?

    { 'present' => true, 'check' => 'contains_any', 'value' => [value.split(',').first.strip.downcase],
      'judge' => true, 'question' => QUESTIONS['governing_law'], 'reference' => value }
  end

  # Full dates check exactly; "perpetual" and year-only answers fall back to the judge;
  # answers the annotators could not read ("[]/[]/[]") are left out.
  def date_field(field, value)
    return { 'present' => false } if value.empty?
    return free_text(field, 'perpetual') if value.casecmp?('perpetual')

    if (m = value.match(%r{\A(\d{1,2})/(\d{1,2})/(\d{2,4})\z}))
      return { 'present' => true, 'check' => 'date', 'value' => iso(m), 'judge' => true,
               'question' => QUESTIONS[field], 'reference' => value }
    end
    if (year = value[%r{\A\[\s*\]/\[\s*\]/(\d{4})\z}, 1])
      return { 'present' => true, 'check' => 'contains_any', 'value' => [year], 'judge' => true,
               'question' => QUESTIONS[field], 'reference' => "in #{year} (day and month not stated)" }
    end
    nil
  end

  def iso(match)
    month, day, year = match.captures.map(&:to_i)
    year += year < 60 ? 2000 : 1900 if year < 100
    format('%<y>04d-%<m>02d-%<d>02d', y: year, m: month, d: day)
  end

  def free_text(field, value)
    return { 'present' => false } if value.empty?

    { 'present' => true, 'check' => 'eq', 'value' => value, 'judge' => true, 'question' => QUESTIONS[field] }
  end
end

CuadSource.run if $PROGRAM_NAME == __FILE__
