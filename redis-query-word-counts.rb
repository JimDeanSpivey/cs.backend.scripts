require 'redis'
require_relative './redis-common.rb'

rco = RedisCommon.new
options = rco.parseCliOptions

# Iterate all keys
redis = Redis.new(:password => options[:password])
redis.keys('wordcounts:*').each { |k|
  date = rco.extractDate k
  # Skip if the date too old (not recent)
  next if !rco.dateRecent date, options[:hours]

  result = redis.zrangebyscore(k, options[:wordCount], '+inf', {withscores: true}) 
  p k, result if !result.empty?
}
