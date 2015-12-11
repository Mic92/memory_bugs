require 'test_helper'
require 'memory_bugs'
require 'pry'

def test_site(site, queue_size)
  describe site do
    before do
      @crawler = MemoryBugs::Crawler.new(sites: [site])
      @site_name = @crawler.site_name(site)
      VCR.use_cassette(@site_name) { @crawler.find_tickets }
    end
    it "should find some tickets" do
      @crawler.ticket_queues[@site_name].size.must_be :>=, queue_size
    end
  end
end

describe MemoryBugs::Crawler do
  test_site(MemoryBugs::Sites::Sqlite, 389)
  test_site(MemoryBugs::Sites::Redis, 2935)
  test_site(MemoryBugs::Sites::Leveldb, 322)
  test_site(MemoryBugs::Sites::Postgres.with_page_limit(2), 497)
  test_site(MemoryBugs::Sites::Mysql.with_page_limit(2), 3000)
  test_site(MemoryBugs::Sites::Mongodb.with_page_limit(2), 2000)
  test_site(MemoryBugs::Sites::Mariadb.with_page_limit(2), 1000)
  test_site(MemoryBugs::Sites::Virtuosu, 506)
  test_site(MemoryBugs::Sites::Memcached, 420)

  describe MemoryBugs::Sites::Sqlite do
    before do
      @crawler = MemoryBugs::Crawler.new(sites: [MemoryBugs::Sites::Sqlite])
      VCR.use_cassette("typhoeus_queue") do
        @crawler.find_tickets
        @site_name = "sqlite"
        @crawler.ticket_queues[@site_name] = @crawler.ticket_queues[@site_name].take(3)
        @crawler.download_tickets
      end
    end
    it "should empty the queue" do
      @crawler.ticket_queues.must_be_empty
    end
  end
  # test_site(MemoryBugs::Sites::Firebird, 420)
end
