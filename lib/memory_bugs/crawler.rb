require 'set'
require 'net/https'
require 'net/http'
require 'typhoeus'
require 'time'

require 'memory_bugs/logging'
require 'memory_bugs/models'
require 'memory_bugs/elasticsearch'

module MemoryBugs
  class Crawler
    def self.register(site)
      DEFAULT_CRAWLER << site
    end

    DEFAULT_CRAWLER = Set.new

    def initialize(sites: DEFAULT_CRAWLER)
      @ticket_queues = {}
      @sites = sites
    end

    attr_reader :ticket_queues

    def site_name(site)
      site.name.split("::").last.downcase
    end

    def find_tickets
      @sites.each do |klass|
        site = klass.new
        queue = []

        @ticket_queues[site_name(klass)] = queue
        next_urls = [site.seed_url]
        seen = Set.new
        until next_urls.empty?
          url = next_urls.pop
          seen << url
          # TODO replace with hydra if it is bottle neck
          document = download(url)
          site.process(url, document, queue) do |next_url|

            next if seen.include?(next_url)
            next_urls << next_url
          end
        end
      end
    end

    def handle_download(site, resp)
      url = resp.effective_url
      if resp.success?
        MemoryBugs::Logger.info("Got page: '#{url}'")

        page = Models::TicketPage.new(site: site,
                                      content: resp.body,
                                      created_at: Time.now.utc.iso8601,
                                      url: url.to_s)
        MemoryBugs::Elasticsearch.create(page)
      elsif resp.timed_out?
        MemoryBugs::Logger.info("Page timed out: '#{url}'")
      elsif resp.code == 0
        MemoryBugs::Logger.info("Failed to request: '#{url}'")
      else
        MemoryBugs::Logger.info("Got #{resp.code} for request: '#{url}'")
      end
    end

    def download_tickets
      hydra = Typhoeus::Hydra.new
      # schedule requests round robbin per site
      while @ticket_queues.size > 0
        @ticket_queues.each do |name, queue|
          if queue.empty?
            @ticket_queues.delete(name)
          else
            req = queue.pop
            req.on_complete { |resp| handle_download(name, resp) }
            hydra.queue(req)
          end
        end
      end
      hydra.run
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
