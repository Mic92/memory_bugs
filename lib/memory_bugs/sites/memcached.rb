require 'csv'

module MemoryBugs
  module Sites
    class Memcached
      def seed_url
        "https://code.google.com/p/memcached/issues/csv?can=1&start=0&num=10000&q=&colspec=ID%20Type%20Status%20Priority%20Milestone%20Owner%20Summary"
      end

      def ticket_url(id)
        "https://code.google.com/p/memcached/issues/detail?id=#{id}&can=1&num=1000"
      end

      def process(url, content, ticket_urls)
        CSV.parse(content, headers: :first_row) do |row|
          ticket_urls.push(ticket_url(row["ID"]))
        end
      end

      MemoryBugs::Crawler.register(Memcached)
    end
  end
end
