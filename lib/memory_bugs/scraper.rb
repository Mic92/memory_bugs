require 'nokogiri'
require 'memory_bugs/models'
require 'memory_bugs/elasticsearch'

module MemoryBugs
  class Scraper
    def self.site_name(site)
      site.name.split("::").last.downcase
    end

    def self.register(site)
      DEFAULT_SCRAPER[site_name(site)] = site
    end

    DEFAULT_SCRAPER = {}

    def initialize(scrapers: DEFAULT_SCRAPER)
      @ticket_queues = {}
      @scrapers = scrapers
    end

    def process_tickets
      k = MemoryBugs::Models::TicketPage
      updates = []
      MemoryBugs::Elasticsearch.scroll(k) do |page|
        scraper = @scrapers[page.site].new
        if scraper.nil?
          MemoryBugs::Logger.warn("no scraper found for #{page.site}")
          next
        end
        tickets = scraper.process(page)
        tickets.each do |ticket|
          ticket.url = page.url
          ticket.site = page.site
        end
        updates.concat(tickets)
        if updates.size > 1000
          MemoryBugs::Elasticsearch.bulk(updates)
          updates.clear
        end
      end
      MemoryBugs::Elasticsearch.bulk(updates) unless updates.empty?
    end
  end
end
