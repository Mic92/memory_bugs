require 'test_helper'
require 'memory_bugs'
require 'pry'

def test_site(site, queue_size)
  match = /::(?<name>[^:]+)$/.match(site.name)
  cassette = match[:name].downcase

  describe site do
    before do
      @crawler = MemoryBugs::Crawler.new(sites: [site])
      VCR.use_cassette(cassette) { @crawler.index_tickets }
    end
    it "should find some tickets" do
      @crawler.ticket_queue.size.must_be :>=, queue_size
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
  # test_site(MemoryBugs::Sites::Firebird, 420)
end
