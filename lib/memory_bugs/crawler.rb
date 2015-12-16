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

    def initialize(sites: DEFAULT_CRAWLER, count: nil)
      @sites = sites
      @downloaded_pages = []
      @count = count
    end

    def site_name(site)
      site.name.split("::").last.downcase
    end

    def put_urls(urls)
      if @count
        return if @count <= 0
        if urls.size >= @count
          urls = urls.take(@count)
        end
        @count -= urls.size
      end

      pages = urls.map do |u|
        Models::TicketPage.new(url: u)
      end
      MemoryBugs::Elasticsearch.bulk(pages)
    end

    def find_tickets
      @sites.each do |klass|
        site = klass.new
        ticket_urls = []

        next_urls = [site.seed_url]
        until next_urls.empty?
          url = next_urls.pop
          document = download(url)
          site.process(url, document, ticket_urls) do |next_url|
            if ticket_urls.size > 1000
              put_urls(ticket_urls)
              ticket_urls.clear
            end
            next_urls << next_url
          end
        end
        unless ticket_urls.empty?
          put_urls(ticket_urls)
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
        @downloaded_pages.push(page)
        if @downloaded_pages.size > 1000
          MemoryBugs::Elasticsearch.bulk(@downloaded_pages)
          @downloaded_pages.clear
        end
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

      search = {
        body: {
          query: {
            function_score: {
              filter: { not: { exists: { field: "content" } } },
              random_score:  { seed: 11 },
            }
          }
        }
      }

      queued_requests = 0
      MemoryBugs::Elasticsearch.scroll(Models::TicketPage,
                                       search: search) do |page|
        req = Typhoeus::Request.new(page.url)
        req.on_complete do |resp|
          handle_download(page.name, resp)
        end
        hydra.queue(req)
        queued_requests += 1
        if queued_requests > 1000
          hydra.run
          queued_requests = 0
        end
      end
      hydra.run if queued_requests > 0
      unless @downloaded_pages.empty?
        MemoryBugs::Elasticsearch.bulk(@downloaded_pages)
        @downloaded_pages.clear
      end
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
