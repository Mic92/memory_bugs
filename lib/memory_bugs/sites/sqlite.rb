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

      def process(url, content, ticket_urls)
        CSV.parse(content,
                  col_sep: "\t",
                  quote_char: "\0",
                  headers: :first_row) do |row|
          ticket_urls.push(ticket_url(row["#"]))
        end
      end
    end
    MemoryBugs::Crawler.register(Sqlite)
  end
end
