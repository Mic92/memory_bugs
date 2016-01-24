require 'nokogiri'
require 'memory_bugs/models'
require 'memory_bugs/elasticsearch'

module MemoryBugs
  class Scraper
    def self.site_name(site)
      site.name.split("::").last.downcase
    end

    def self.register(site)
      DEFAULT_SCRAPER[site_name(site)] = site.new
    end

    DEFAULT_SCRAPER = {}

    def initialize(scrapers: DEFAULT_SCRAPER)
      @ticket_queues = {}
      @scrapers = scrapers
    end

    def process_tickets
      k = MemoryBugs::Models::TicketPage
      updates = []

      search = {
        body: {
          query: {
            function_score: {
              filter: { and: [
                { exists: { field: "content" } },
                { or: [
                  { term: { scraped: false } },
                  { not: { exists: { field: "scraped" } } },
                ]}
              ]}
            }
          }
        }
      }
      MemoryBugs::Elasticsearch.scroll(k, search: search) do |page|
        MemoryBugs::Logger.info("scrape #{page.url}")
        scraper = @scrapers[page.site]
        if scraper.nil?
          MemoryBugs::Logger.warn("no scraper found for #{page.site}")
          next
        end
        tickets = scraper.process(page.content)
        tickets.each do |ticket|
          ticket.url = page.url
          ticket.site = page.site
        end
        updates.concat(tickets)
        new_page = Models::TicketPage.new(url: page.url, scraped: true)
        updates.push(new_page)

        if updates.size > 1000
          MemoryBugs::Elasticsearch.bulk(updates)
          updates.clear
        end
      end
      unless updates.empty?
        MemoryBugs::Elasticsearch.bulk(updates)
      end
    end
  end
end
