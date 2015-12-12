require 'test_helper'

describe MemoryBugs::Scraper do
  describe MemoryBugs::Scrapers::Sqlite do
    before do
      @crawler = MemoryBugs::Crawler.new(sites: [MemoryBugs::Sites::Sqlite])
      MemoryBugs::Elasticsearch.delete_index rescue 0
      MemoryBugs::Elasticsearch.create_mapping

      VCR.use_cassette("typhoeus_queue") do
        @crawler.find_tickets
        @site_name = "sqlite"
        @crawler.ticket_queues[@site_name] = @crawler.ticket_queues[@site_name].take(3)
        @crawler.download_tickets
        MemoryBugs::Elasticsearch.refresh

        @scraper = MemoryBugs::Scraper.new
        @scraper.process_tickets

        MemoryBugs::Elasticsearch.count.must_be :==, 3
      end
    end

    it "should empty the queue" do
      @crawler.ticket_queues.must_be_empty
    end
  end
end
