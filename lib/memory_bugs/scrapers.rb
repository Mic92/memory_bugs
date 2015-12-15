require "memory_bugs/scraper"
require "memory_bugs/scrapers/helpers"

sites = %w{sqlite postgres leveldb redis memcached mongodb mariadb mysql virtuoso}
sites.each do |site|
  require "memory_bugs/scrapers/#{site}"
end
