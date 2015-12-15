require 'test_helper'

def test_scraper(scraper_kls)
  describe scraper_kls do
    before do
      scraper = scraper_kls.new
      name = scraper_kls.name.split("::").last.downcase
      @tickets = scraper.process(File.open(fixture_path("#{name}.html")))
    end
    it { @tickets.size.must_be :==, 1 }
  end
end

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
      end
    end

    it "should empty the queue" do
      MemoryBugs::Elasticsearch.refresh
      MemoryBugs::Elasticsearch.count.must_be :==, 6
      @crawler.ticket_queues.must_be_empty
    end
  end

  describe MemoryBugs::Scrapers::Postgres do
    before do
      scraper = MemoryBugs::Scrapers::Postgres.new
      @tickets = scraper.process(File.open(fixture_path("postgres.html")))
    end
    it "should scrape the page" do
      @tickets.size.must_be :==, 1
      t = @tickets.first
      t.title.wont_be_nil
      t.description.wont_be_nil
      t.external_id.wont_be_nil
      t.comments.wont_be_nil
      t.created_at.must_be_instance_of Time
    end
  end

  # example for Github
  test_scraper(MemoryBugs::Scrapers::Leveldb)
  test_scraper(MemoryBugs::Scrapers::Memcached)
  # example for Jira
  test_scraper(MemoryBugs::Scrapers::Mongodb)
  test_scraper(MemoryBugs::Scrapers::Mysql)
end
