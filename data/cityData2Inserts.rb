require 'active_support/all'

'''
Fields table:
The main "geoname" table has the following fields :
---------------------------------------------------
geonameid         : integer id of record in geonames database
name              : name of geographical point (utf8) varchar(200)
asciiname         : name of geographical point in plain ascii characters, varchar(200)
alternatenames    : alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
latitude          : latitude in decimal degrees (wgs84)
longitude         : longitude in decimal degrees (wgs84)
feature class     : see http://www.geonames.org/export/codes.html, char(1)
feature code      : see http://www.geonames.org/export/codes.html, varchar(10)
country code      : ISO-3166 2-letter country code, 2 characters
cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 200 characters
admin1 code       : fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
admin2 code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
admin3 code       : code for third level administrative division, varchar(20)
admin4 code       : code for fourth level administrative division, varchar(20)
population        : bigint (8 byte int) 
elevation         : in meters, integer
dem               : digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
  timezone          : the timezone id (see file timeZone.txt) varchar(40)
modification date : date of last modification in yyyy-MM-dd format
'''
class CityData
  attr_accessor \
    :name,
    :latitude,
    :longitude,
    :country_code, 
    :country_name,
    :state_code,
    :state_name,
    :population,
    :timezone,
    :require_state, #Most cities have a unique name, however small cities can have common names
    :require_country
end

def getCountryNames()
  result = {}
  f = File.open('countryInfo.txt', 'r')
  f.each_line { |l|
    next if l.starts_with? '#' 
    c = l.split /\t/
    result[c[0]] = c[4]
  }  
  result
end

def getStateNames()
  result = {}
  f = File.open('admin1CodesASCII.txt', 'r')
  f.each_line { |l|
    c = l.split /\t/
    result[c[0]] = c[1]
  }
  result
end

def sanitizeName(name)
  name.gsub(/[^a-z0-9\s]/i, '')
end

def toInsert(data)
  "INSERT INTO city (name, latitude, longitude, country_code,
  state_code, require_country, require_state, population) values (
  '#{data.name}', #{data.latitude}, #{data.longitude},
  '#{data.country_code}', '#{data.state_code}', '#{data.require_country}',
  '#{data.require_state}', #{data.population});"
end

countryNames = getCountryNames()
stateNames = getStateNames()
duplicateCities = [
  'Borough of Queens',
  'Brooklyn',
  'Manhattan',
  'New South Memphis',
  'Santa Ana',
  'South Boston',
  'Staten Island',
  'The Bronx',
  'West Raleigh',
  #TODO: there are certainly more cities to filter, these are the largest though
]


f = File.open('cities5000.txt', 'r')
f.each_line { |l| 
  c = l.split /\t/
  
  next if duplicateCities.include? c[1]

  data = CityData.new
  data.name = c[1]
  data.search_name = sanitizeName c[1]
  data.search_aliases = []
  data.latitude = c[4].to_f
  data.longitude = c[5].to_f
  data.country_code = c[8]
  data.country_name = countryNames[data.country_code]
  data.state_code = c[10] if data.country_code.eql? 'US'
  data.state_name = stateNames[data.country_code + '.' +c[10]]
  data.population = c[14].to_i
  data.timezone = c[17]

  case data.country_code
  when 'US'
    if data.population < 250000
      data.require_state = 'true'
    else
      data.require_state = 'false'
    end
    data.require_country = 'false'
  else
    data.require_state = 'false' #People rarely refer to provinces/states outside of the US, in the news
    if data.population < 1000000 or ['CN', 'IN'].include?(data.country_code)
      data.require_country = 'true'
    else
      data.require_country = 'false'
    end
  end

  puts toInsert(data)

  #p stateNames
  #p c
  #puts data.to_json

  #p c[8]
  #p c[10]

  #exit
}


