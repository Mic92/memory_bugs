require 'memory_bugs/scrapers/jira'

module MemoryBugs
  module Scrapers
    class Mariadb
      include MemoryBugs::Scrapers::Jira
    end

    MemoryBugs::Scraper.register(Mariadb)
  end
end
