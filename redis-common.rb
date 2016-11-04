require 'date'
require 'active_support/all'
require 'optparse'

class RedisCommon

  attr_accessor :options

  def parseCliOptions()

    @options = {}
    OptionParser.new do |opt|
      opt.on('-a', '--age HOURS', OptionParser::DecimalInteger,
             'How old the twitter word count, measured in hours.') { |o| @options[:hours] = o }
      opt.on('-w', '--wordCount COUNT', OptionParser::DecimalInteger,
             'Word counts lower than this will be deleted.') { |o| @options[:wordCount] = o }
      opt.on('-p', '--password PASSWORD', OptionParser::String,
             'Word counts lower than this will be deleted.') { |o| @options[:password] = o }
      opt.on('-v', '--verbose') { |o| options[:verbose] = true }
      opt.on('-h', '--help') { |o| options[:help] = true }
    end.parse!
    raise OptionParser::MissingArgument if @options[:hours].nil?
    raise OptionParser::MissingArgument if @options[:wordCount].nil?

    @options
  end

  def extractDate(key)
    DateTime.strptime(key.split(':')[2..3].join, '%Y%m%d%H%M')
  end

  def dateRecent(keyDate, arg)
    DateTime.now < keyDate.advance(:hours => arg)
  end
end
