require 'memory_bugs/scrapers/googlecode'

module MemoryBugs
  module Scrapers
    class Memcached
      include MemoryBugs::Scrapers::Googlecode
    end

    MemoryBugs::Scraper.register(Memcached)
  end
end
