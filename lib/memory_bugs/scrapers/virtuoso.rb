require 'memory_bugs/scrapers/github'

module MemoryBugs
  module Scrapers
    class Virtuosu
      include MemoryBugs::Scrapers::Github
    end
    MemoryBugs::Scraper.register(Virtuosu)
  end
end
