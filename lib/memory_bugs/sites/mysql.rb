require 'csv'

module MemoryBugs
  module Sites
    class Mysql
      include MemoryBugs::Pagination

      def seed_url
        paged_url(0)
      end

      def paged_url(skip_entries)
        "https://bugs.mysql.com/search-csv.php?status=All&os=0&bug_age=0&order_by=id&direction=ASC&limit=All&begin=#{skip_entries}"
      end

      def ticket_url(id)
        "https://bugs.mysql.com/bug.php?id=#{id}"
      end

      def process(url, content, ticket_urls, &blk)
        has_tickets = false
        CSV.parse(content, headers: :first_row) do |row|
          has_tickets = true
          ticket_urls.push(ticket_url(row["ID"]))
        end

        paginate(1000, &blk) if url == seed_url
        return has_tickets
      end
    end
    MemoryBugs::Crawler.register(Mysql)
  end
end
