require 'memory_bugs/scrapers/github'

module MemoryBugs
  module Scrapers
    class Leveldb
      include MemoryBugs::Scrapers::Github
    end
    MemoryBugs::Scraper.register(Leveldb)
  end
end
