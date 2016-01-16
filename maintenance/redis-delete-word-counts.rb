require 'redis'
require_relative '../redis-common.rb'

rco = RedisCommon.new
options = rco.parseCliOptions

if options[:help]
  puts 'Deletes all zsets from the range of 0 to [--wordCount arguement]. But only if they are older than [--age] in hours.'
  puts 'Example usage: rb redis-delete-word-counts.rb -w 5  -a 24 will delete all scores that are both older than 1 day and below a score of 5.'
  puts 'Example usage: rb redis-delete-word-counts.rb -w 9999999 -a -1 will delete all zsets. '
  exit
end

# Iterate all keys
redis = Redis.new
redis.keys('*').each { |k|
  date = rco.extractDate k
  next if rco.dateRecent date, options[:hours]

  # Delete all hash elements with low word counts
  begin
    redis.zremrangebyscore(k, 0, options[:wordCount])
  rescue Redis::TimeoutError => e
    puts 'Warning: #{e}'
  end
}
