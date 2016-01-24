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

    def put_urls(site, urls)
      if @count
        return if @count <= 0
        if urls.size >= @count
          urls = urls.take(@count)
        end
        @count -= urls.size
      end

      pages = urls.map do |u|
        Models::TicketPage.new(url: u, site: site)
      end
      MemoryBugs::Elasticsearch.bulk(pages)
    end

    def crawl_url(site, name, url, ticket_urls)
      document = download(url)
      site.process(url, document, ticket_urls) do |next_url|
        if ticket_urls.size > 1000
          put_urls(name, ticket_urls)
          ticket_urls.clear
        end
        unless crawl_url(site, name, next_url, ticket_urls)
          break
        end
      end
    end

    def find_tickets
      @sites.each do |klass|
        site = klass.new
        name = site_name(klass)
        ticket_urls = []

        crawl_url(site, name, site.seed_url, ticket_urls)
        unless ticket_urls.empty?
          put_urls(name, ticket_urls)
        end
      end
    end

    def handle_download(site, url, resp)
      if resp.success?
        MemoryBugs::Logger.info("Got page: '#{url}'")

        page = Models::TicketPage.new(site: site,
                                      content: resp.body.force_encoding("utf-8"),
                                      created_at: Time.now.utc,
                                      url: url,
                                      scraped: false)
        @downloaded_pages.push(page)
        if @downloaded_pages.size > 100
          MemoryBugs::Elasticsearch.bulk(@downloaded_pages)
          @downloaded_pages.clear
        end
      elsif resp.timed_out?
        MemoryBugs::Logger.info("Page timed out: '#{url}'")
      elsif resp.code == 0
        MemoryBugs::Logger.info("Failed to request: '#{url}'")
      else
        page = Models::TicketPage.new(error_status: resp.code.to_i, url: url)
        @downloaded_pages.push(page)
        MemoryBugs::Logger.info("Got #{resp.code} for request: '#{url}'")
      end
    end

    def download_tickets
      hydra = Typhoeus::Hydra.new(max_concurrency: 20)
      # schedule requests round robbin per site

      search = {
        body: {
          query: {
            function_score: {
              filter: { and: [
                { not: { exists: { field: "content" } } },
                { not: { exists: { field: "error_status" } } },
              ]},
            }
          }
        }
      }

      queued_requests = 0
      MemoryBugs::Elasticsearch.scroll(Models::TicketPage,
                                       search: search) do |page|
        req = Typhoeus::Request.new(page.url,
                                    accept_encoding: "gzip",
                                    headers: { Accept: "text/html" })
        req.on_complete do |resp|
          handle_download(page.site, page.url, resp)
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
