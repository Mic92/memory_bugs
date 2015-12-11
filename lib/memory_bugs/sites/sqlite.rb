require 'csv'

module MemoryBugs
  module Sites
    class Sqlite
      def seed_url
        # TODO: Only selected bugs, not mailinglist
        "https://www.sqlite.org/src/rptview?tablist=1&rn=1"
      end

      def ticket_url(id)
        "https://www.sqlite.org/src/tktview?name=#{id}"
      end

      def process(url, content, ticket_queue)
        CSV.parse(content,
                  col_sep: "\t",
                  quote_char: "\0",
                  headers: :first_row) do |row|
          request = Typhoeus::Request.new(ticket_url(row["#"]))
          ticket_queue.push(request)
        end
      end
    end
    MemoryBugs::Crawler.register(Sqlite)
  end
end
