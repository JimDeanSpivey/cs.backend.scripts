require 'pg'
require 'optparse'
require_relative './node-setup-common.rb'

NODE_NAME = 'Apricot'
COUNTRY_CODES = [ 'US', 'TH' ]

begin
  options = parseCliOptions
  pg = PG.connect :host => '10.0.2.5', :dbname => 'crowdsig', :user => 'crowdsig', :password => options[:password]

  #Get large/uniquely named cities, aprox 100 cities with a pop are above 300,000
  city_ids = getCitiesFrom pg, ['US'], 300_000
  city_ids.each do |city|
    puts toSqlInsert(NODE_NAME, city['id'])
  end
ensure
  pg.close if pg
end
