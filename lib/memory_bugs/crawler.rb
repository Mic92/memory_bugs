require 'thread'
require 'set'
require 'memory_bugs/logging'
require 'open-uri'
require 'net/https'
require 'net/http'

module MemoryBugs
  class Crawler
    def self.register(site)
      DEFAULT_CRAWLER << site
    end

    DEFAULT_CRAWLER = Set.new

    def initialize(sites: DEFAULT_CRAWLER)
      @ticket_queue = Queue.new
      @sites = sites
    end

    attr_reader :ticket_queue

    def index_tickets
      @sites.each do |klass|
        site = klass.new
        next_urls = [site.seed_url]
        seen = Set.new
        until next_urls.empty?
          url = next_urls.pop
          seen << url
          document = download(url)
          site.process(url, document, @ticket_queue) do |next_url|
            next if seen.include?(next_url)
            next_urls << next_url
          end
        end
      end
    end

    def download_tickets
    end

    def download(url)
      MemoryBugs::Logger.info("Download url: '#{url}'")
      response = Net::HTTP.get_response(URI(url))
      code = response.code
      unless code.start_with?("2")
        raise MemoryBugs::Error.new("Error while downloading #{url}: expect to get http code 200, got #{code}")
      end
      response.body
    end
  end
end
