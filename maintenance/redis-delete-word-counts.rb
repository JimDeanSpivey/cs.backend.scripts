require 'redis'
require_relative '../redis-common.rb'

rco = RedisCommon.new
options = rco.parseCliOptions

# Iterate all keys
redis = Redis.new
redis.keys('*').each { |k|
  date = rco.extractDate k
  next if rco.dateRecent date, options[:hours]

  # Delete all hash elements with low word counts
  redis.zremrangebyscore(k, 0, options[:wordCount])
}
