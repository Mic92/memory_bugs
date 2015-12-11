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

      def process(url, content, ticket_queue)
        CSV.parse(content, headers: :first_row) do |row|
          req = MemoryBugs::Request.new(ticket_url(row["ID"]))
          ticket_queue.push(req)
        end
      end
    end
  end
end
