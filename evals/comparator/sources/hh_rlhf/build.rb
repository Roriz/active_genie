# frozen_string_literal: true

# Drafts comparator cases from Anthropic's hh-rlhf, helpful-base test split (MIT, see NOTICE.md in
# this folder).
#
#   bundle exec ruby evals/comparator/sources/hh_rlhf/build.rb
#
# Reads the split from data/helpful-base-test.jsonl.gz, a verbatim copy of the upstream file at a
# pinned revision (URL below), and checks its SHA-256. Each row is one conversation with two
# possible last replies, and a crowdworker's pick of the more helpful one. The picks are noisy, so
# the cases are added to evals/comparator/datasets.jsonl as drafts: a case runs only when two blind
# labeling passes agree with the crowdworker (`rake active_genie:eval:label EVAL=comparator`);
# otherwise it is dropped, not queued. Both variants (by_debate and by_fight) run the same cases, so
# the two methods are compared on paired cases.
#
# Picks short, benign conversations whose two replies are both real answers, half where the picked
# reply is the longer one and half where it is the shorter one, so length alone cannot win. Which
# reply is player_a is decided by a hash of the case, so the gold is a mix of "a" and "b".
# Re-running adds only ids the dataset does not have yet, so it never touches a row already labeled.

require 'zlib'
require_relative '../../../../lib/active_genie'
require_relative '../../../../lib/active_genie/eval'

module HhRlhfSource
  # Provenance: FILE is this upstream file, unmodified. Fetch it and compare SHA-256s to check.
  REVISION = '09be8c5bbc57cb3887f3a9732ad6aa7ec602a1fa'
  URL = "https://huggingface.co/datasets/Anthropic/hh-rlhf/resolve/#{REVISION}/helpful-base/test.jsonl.gz".freeze
  SHA256 = '8be3fc1a13b27901631696f2be6f184c799f1baeaf145f53ac5db24960adc37b'
  REPO = File.expand_path('../../../..', __dir__)
  FILE = File.join(__dir__, 'data', 'helpful-base-test.jsonl.gz')
  PER_LENGTH_SIDE = 40

  MAX_USER_TURNS = 2
  MAX_CONTEXT_CHARS = 1200
  REPLY_CHARS = (40..900)
  # Topics kept out of the eval: the split is about helpfulness, but some prompts are not.
  SENSITIVE = /\b(sex\w*|porn\w*|nude|naked|drugs?|cocaine|heroin|meth|weed|marijuana|kill\w*|murder\w*|
                 guns?|weapons?|bombs?|suicid\w*|steal\w*|rob\w*|racis\w*|slurs?|hack\w*|poison\w*|
                 abuse\w*|rape|terror\w*|nazi\w*|cheat\w*|revenge|hate|violen\w*|fuck\w*|shit\w*|bitch\w*)\b/ix

  # A turn that writes the next turn itself ("Human: ...") is transcript debris, not an answer.
  TURN_MARKER = /\b(?:Human|Assistant):/

  CRITERIA = 'Which reply is more helpful as the assistant\'s next message in this conversation?'

  module_function

  def run
    verify!

    candidates = Zlib::GzipReader.open(FILE, external_encoding: Encoding::UTF_8) do |gz|
      gz.each_line.filter_map { |line| candidate(JSON.parse(line)) }
    end
    picked = candidates.group_by { |c| c[:length] }.values.flat_map do |group|
      group.sort_by { |c| c[:id] }.first(PER_LENGTH_SIDE)
    end
    # Fewer on one side would let a length preference pay.
    raise "only #{picked.size} drafts, want #{PER_LENGTH_SIDE} per length side" unless picked.size == 2 * PER_LENGTH_SIDE

    ActiveGenie::Eval.app_root = REPO
    definition = ActiveGenie::Eval.fetch('comparator')
    rows = ActiveGenie::Eval::Store.rows(definition)
    known = rows.to_set { |r| r['id'] }
    added = picked.sort_by { |c| c[:id] }.reject { |c| known.include?(c[:id]) }.map { |c| draft(c) }
    ActiveGenie::Eval::Store.write_rows(definition, (rows + added).sort_by { |r| r['id'] })
    puts "comparator: #{added.size} new drafts (#{picked.size} picked from #{candidates.size} candidates)"
    puts 'Label them (rake active_genie:eval:blind EVAL=comparator),'
    puts 'then rake active_genie:eval:label EVAL=comparator'
  end

  def verify!
    raise "#{FILE} is missing: restore it from git, or fetch #{URL}" unless File.exist?(FILE)
    return if Digest::SHA256.file(FILE).hexdigest == SHA256

    raise "#{FILE}: SHA-256 mismatch, it no longer matches #{URL}; restore it from git"
  end

  # Both texts are the same conversation up to the last reply.
  def candidate(row)
    chosen = turns(row['chosen'])
    rejected = turns(row['rejected'])
    return unless chosen && rejected && chosen[0...-1] == rejected[0...-1]
    return unless chosen.last[0] == 'Assistant' && rejected.last[0] == 'Assistant'

    context = chosen[0...-1]
    good = chosen.last[1]
    bad = rejected.last[1]
    return unless usable?(context, good, bad)

    id = "hh_#{Digest::SHA256.hexdigest(row['chosen'])[0, 10]}"
    { id:, context:, good:, bad:, length: good.size > bad.size ? 'picked_longer' : 'picked_shorter' }
  end

  def turns(text)
    parts = text.split(/\n\n(Human|Assistant): /)
    return if parts.size < 3

    parts.drop(1).each_slice(2).map { |role, body| [role, body.to_s.strip] }
  end

  def usable?(context, good, bad)
    return false if context.count { |role, _| role == 'Human' } > MAX_USER_TURNS
    return false if context.sum { |_, body| body.size } > MAX_CONTEXT_CHARS
    return false unless REPLY_CHARS.cover?(good.size) && REPLY_CHARS.cover?(bad.size)
    return false if good.size == bad.size # neither is the longer one: no `tags.length`
    return false if good.casecmp?(bad) || good.start_with?(bad) || bad.start_with?(good)

    bodies = [good, bad] + context.map(&:last)
    bodies.none? { |body| body.match?(SENSITIVE) || body.match?(TURN_MARKER) }
  end

  def draft(cand)
    good_is_a = Digest::SHA256.hexdigest("#{cand[:id]}:side").to_i(16).even?
    player_a, player_b = good_is_a ? [cand[:good], cand[:bad]] : [cand[:bad], cand[:good]]
    { 'id' => cand[:id], 'pool' => 'test', 'status' => 'draft', 'source' => 'hh-rlhf',
      'tags' => { 'domain' => 'chat', 'difficulty' => 'subtle', 'length' => cand[:length],
                  'user_turns' => cand[:context].count { |role, _| role == 'Human' } },
      'input' => { 'player_a' => player_a, 'player_b' => player_b,
                   'criteria' => "#{CRITERIA}\n\nConversation:\n#{transcript(cand[:context])}" },
      'gold' => { 'winner' => good_is_a ? 'a' : 'b' },
      'why' => 'hh-rlhf helpful-base test: the crowdworker picked this reply as more helpful.',
      'on_disagreement' => 'drop' }
  end

  def transcript(context)
    context.map { |role, body| "#{role == 'Human' ? 'User' : 'Assistant'}: #{body}" }.join("\n\n")
  end
end

HhRlhfSource.run if $PROGRAM_NAME == __FILE__
