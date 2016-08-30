require 'rest_client'
require 'redis'
require 'json'
require_relative '../redis-common.rb'

rco = RedisCommon.new
options = rco.parseCliOptions

if options[:help]
  puts 'Archives (to couchdb) all zsets from the range of [--wordCount arguement] to +inf. But only if they are older than [--age] in hours.'
  puts 'Example usage: rb redis-archive-word-counts.rb -w 5  -a 24 will archive all scores that are both older than 1 day and above a score of 5.'
  puts 'Example usage: rb redis-archive-word-counts.rb -w -1 -a -1 will archive all zsets. '
  exit
end

log = Logger.new(STDOUT)
log.level = Logger::ERROR
if options[:verbose]
  log.level = Logger::INFO
end

hashesByTime = Hash.new
# Iterate all keys
redis = Redis.new
redis.keys('*').each { |k| # I should probably not query by '*' but it's not possible to do searchs with * unless it is the last character.
  date = rco.extractDate k
  # Skip if the date too recent (not old enough to archive)
  next if rco.dateRecent date, options[:hours]

  result = redis.zrangebyscore(k, options[:wordCount], '+inf', {withscores: true})
  next if result.empty?
  #p k.split(':').first, result if !result.empty?
  #p result.to_json

  #1. Get key as date/time only
  dateKey = k.split(':')[1, 2].join(':')
  cityKey = k.split(':')[0]
  #2. Get or make hash for that date/time bucket. Key for this hash is the city name, the last qualifier for the original key
  hash = hashesByTime[dateKey]
  if hash.nil?
    hash = Hash.new
    hashesByTime[dateKey] = hash
  end
  hash[cityKey] = result
  

  #hash = { k.split(':').first => result }
  #hashesByTime[key] = hash

  #don't invoke deleting in this script (DRY). Instead just report on counts at the end of the script
  #in order to singal success
}

log.info "Found #{+hashesByTime.size.to_s} date/time buckets of word-counts to persist."

output = hashesByTime.to_json
saveCount = 0
hashesByTime.each do |k,v|
  log.info "Key: [#{k}] -. JSON: #{v.to_json}"
  uri = URI.encode("wordcounts/" + k)
  begin
    RestClient.put 'http://localhost:5984/' + uri, v.to_json, {:content_type => :json}
    saveCount += 1
    log.info "Success. Sent document #{k} containing #{v.size} records to couchdb."
  rescue RestClient::Conflict
    # Simply rescue and continue to the next record if there is a conflict. But print a notification.
    # todo: consider adding logic to delete and re-submit the latest data to couchdb
    log.error "409 - Document conflict found for #{k}"
  end
end

log.info "Saved #{saveCount} date/time word-count buckets out of #{hashesByTime.size} total found." 
