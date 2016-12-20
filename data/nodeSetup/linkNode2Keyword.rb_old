require 'pg'

def toSqlInsert(node, word)
  "insert into keyword_twitter_api_node (api_node_id, keyword_id) values
  (#{node}, #{word});"
end

begin
  pg = PG.connect :host => 'localhost', :dbname => 'crowdsig', :user => 'crowdsig'

  node = pg.exec "select id from twitter_api_node where name = 'local';"
  node = node.values[0][0]

  #TODO: this SQL will be a parameter. Different queries will be saved somewhere as well.
  keywords = pg.exec "
      select k.id from city c
      join keyword k on c.name = k.name
      where population > 300000
      and country_code in ('US', 'TH')
      and require_country = false;
  "

  keywords.each do |word|
    puts toSqlInsert(node, word['id'])
  end
#rescue PG::Error => e
#  puts e.message 
ensure
  pg.close if pg
end
