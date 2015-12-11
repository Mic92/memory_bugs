require 'typhoeus'
require 'memory_bugs/pagination'

sites = %w{memcached mysql postgres redis sqlite leveldb mongodb mariadb virtuoso}
sites.each do |site|
  require "memory_bugs/sites/#{site}"
end
