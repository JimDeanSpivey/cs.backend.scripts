require 'date'
require 'active_support/all'
require 'redis'
require 'optparse'

# Parse args
options = {}
OptionParser.new do |opt|
  opt.on('-a', '--age HOURS', OptionParser::DecimalInteger,
         'How old the twitter word count, measured in hours.') { |o| options[:hours] = o }
  opt.on('-w', '--wordCount COUNT', OptionParser::DecimalInteger,
         'Word counts lower than this will be deleted.') { |o| options[:wordCount] = o }
end.parse!
raise OptionParser::MissingArgument if options[:hours].nil?
raise OptionParser::MissingArgument if options[:wordCount].nil?

def extractDate(key)
  DateTime.strptime(key.split(':')[1..2].join, '%Y%m%d%H%M')
end

def dateRecent(keyDate, arg)
  DateTime.now < keyDate.advance(:hours => arg)
end


# Iterate all keys
redis = Redis.new
redis.keys('*').each { |k|
  date = extractDate k
  next if dateRecent date, options[:hours]

  # Delete hashes with low word counts
  redis.zrangebyscore(k, 0, options[:wordCount]).each { |kz| 
    p "deleting #{k} : #{kz}" #TODO: add as CLI parm to control verbosity
    redis.zrem(k, kz)
  }
}
