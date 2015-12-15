require 'memory_bugs/scrapers/jira'

module MemoryBugs
  module Scrapers
    class Mongodb
      include MemoryBugs::Scrapers::Jira
    end

    MemoryBugs::Scraper.register(Mongodb)
  end
end
