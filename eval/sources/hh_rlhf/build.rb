# frozen_string_literal: true

# Drafts comparator cases from Anthropic's hh-rlhf, helpful-base test split (MIT, see NOTICE.md in
# this folder).
#
#   bundle exec ruby eval/sources/hh_rlhf/build.rb
#
# Downloads the split into tmp/datasets/hh_rlhf (gitignored) at a pinned revision and checks its
# SHA-256. Each row is one conversation with two possible last replies, and a crowdworker's pick of
# the more helpful one. The picks are noisy, so the cases are written as drafts: a case enters the
# test pool only when two blind labeling passes agree with the crowdworker (`rake eval:label
# CELL=comparator`); otherwise it is dropped, not queued. The same cases go to by_debate and
# by_fight, so the two methods can be compared on paired cases.
#
# Picks short, benign conversations whose two replies are both real answers, half where the picked
# reply is the longer one and half where it is the shorter one, so length alone cannot win. Which
# reply is player_a is decided by a hash of the case, so the gold is a mix of "a" and "b".
# Re-running rewrites the same drafts.

require 'zlib'
require_relative '../../lib/genie_eval'

module HhRlhfSource
  REVISION = '09be8c5bbc57cb3887f3a9732ad6aa7ec602a1fa'
  URL = "https://huggingface.co/datasets/Anthropic/hh-rlhf/resolve/#{REVISION}/helpful-base/test.jsonl.gz".freeze
  SHA256 = '8be3fc1a13b27901631696f2be6f184c799f1baeaf145f53ac5db24960adc37b'
  FILE = File.join(GenieEval::REPO, 'tmp', 'datasets', 'hh_rlhf', 'helpful-base-test.jsonl.gz')
  SET = 'comparator'
  CELLS = %w[comparator.by_debate comparator.by_fight].freeze
  PER_LENGTH_SIDE = 40

  MAX_USER_TURNS = 2
  MAX_CONTEXT_CHARS = 1200
  REPLY_CHARS = (40..900)
  # Topics kept out of the eval: the split is about helpfulness, but some prompts are not.
  SENSITIVE = /\b(sex\w*|porn\w*|nude|naked|drugs?|cocaine|heroin|meth|weed|marijuana|kill\w*|murder\w*|
                 guns?|weapons?|bombs?|suicid\w*|steal\w*|rob\w*|racis\w*|slurs?|hack\w*|poison\w*|
                 abuse\w*|rape|terror\w*|nazi\w*|cheat\w*|revenge|hate|violen\w*|fuck\w*|shit\w*|bitch\w*)\b/ix

  CRITERIA = 'Which reply is more helpful as the assistant\'s next message in this conversation?'

  module_function

  def run
    download unless File.exist?(FILE)
    raise "#{FILE}: SHA-256 mismatch, refusing to use it" unless Digest::SHA256.file(FILE).hexdigest == SHA256

    candidates = Zlib::GzipReader.open(FILE) { |gz| gz.each_line.filter_map { |line| candidate(JSON.parse(line)) } }
    picked = candidates.group_by { |c| c[:length] }.values.flat_map do |group|
      group.sort_by { |c| c[:id] }.first(PER_LENGTH_SIDE)
    end
    drafts = picked.sort_by { |c| c[:id] }.map { |c| draft(c) }
    GenieEval::Store.write_jsonl(GenieEval.path('labeling', 'drafts', "#{SET}.jsonl"), drafts)
    puts "#{SET}: #{picked.size} drafts from #{candidates.size} candidates; label them, then rake eval:label CELL=#{SET}"
  end

  def download
    FileUtils.mkdir_p(File.dirname(FILE))
    system('curl', '-sSL', '-o', FILE, URL, exception: true)
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
    return false if good.casecmp?(bad) || good.start_with?(bad) || bad.start_with?(good)

    ([good, bad] + context.map(&:last)).none? { |body| body.match?(SENSITIVE) }
  end

  def draft(cand)
    good_is_a = Digest::SHA256.hexdigest("#{cand[:id]}:side").to_i(16).even?
    player_a, player_b = good_is_a ? [cand[:good], cand[:bad]] : [cand[:bad], cand[:good]]
    { 'id' => cand[:id], 'cells' => CELLS, 'source' => 'hh-rlhf',
      'tags' => { 'domain' => 'chat', 'difficulty' => 'subtle', 'length' => cand[:length],
                  'user_turns' => cand[:context].count { |role, _| role == 'Human' } },
      'input' => { 'player_a' => player_a, 'player_b' => player_b,
                   'criteria' => "#{CRITERIA}\n\nConversation:\n#{transcript(cand[:context])}" },
      'gold' => { 'winner' => good_is_a ? 'a' : 'b' },
      'on_disagreement' => 'drop', 'labeled_by' => 'hh-rlhf crowdworker, confirmed by 2 blind passes',
      'why' => 'hh-rlhf helpful-base test: the crowdworker picked this reply as more helpful, and both ' \
               'blind labelers agreed.' }
  end

  def transcript(context)
    context.map { |role, body| "#{role == 'Human' ? 'User' : 'Assistant'}: #{body}" }.join("\n\n")
  end
end

HhRlhfSource.run if $PROGRAM_NAME == __FILE__
