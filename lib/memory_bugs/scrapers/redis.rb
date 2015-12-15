require 'memory_bugs/scrapers/github'

module MemoryBugs
  module Scrapers
    class Redis
      include MemoryBugs::Scrapers::Github
    end
    MemoryBugs::Scraper.register(Redis)
  end
end
