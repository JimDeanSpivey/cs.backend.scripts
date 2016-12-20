def parseCliOptions()
  @options = {}
  OptionParser.new do |opt|
    opt.on('-p', '--password PASSWORD', OptionParser::String,
           'postgresql password.') { |o| @options[:password] = o }
  end.parse!
  raise OptionParser::MissingArgument if @options[:password].nil?

  @options
end

def toSqlInsert(node, city)
  "insert into city_twitter_api_node (api_node_id, city_id) values
  ((SELECT id FROM twitter_api_node WHERE name = '#{node}'), #{city});"
end

def getNodeId(pg, nodeName)
  node = pg.exec "select id from twitter_api_node where name = '#{nodeName}';"
  node = node.values[0][0]
end

def getCitiesFrom(pg, country_codes, population)
  country_codes.map!{ |e| "'#{e}'"} #Wrap each item into single quotes
  pg.exec "
      select id from city c
      where population > #{population}
      and country_code in (#{country_codes.join(',').chomp(',')})
      ;
  "
end
