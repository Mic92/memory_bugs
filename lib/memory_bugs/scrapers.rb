sites = %w{memcached mysql postgres redis sqlite leveldb mongodb mariadb virtuoso}
sites.each do |site|
  require "memory_bugs/scraper/#{site}"
end
