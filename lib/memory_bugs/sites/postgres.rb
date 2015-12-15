require 'nokogiri'

module MemoryBugs
  module Sites
    class Postgres
      include MemoryBugs::Pagination

      def seed_url
        "http://www.postgresql.org/list/pgsql-bugs/"
      end

      def ticket_url(message)
        "http://www.postgresql.org/message-id/flat/#{message}"
      end

      def process(url, content, ticket_queue)
        doc = Nokogiri::HTML(content)
        if url == seed_url
          doc.css("#pgContentWrap ul li a:first-child").each_with_index do |link, i|
            if i > self.class.page_limit
              return true
            end
            yield "http://www.postgresql.org#{link["href"]}"
          end
        else
          doc.css("#pgContentWrap ul li a").each do |link|
            next unless link.text =~ /^BUG #/
            ticket_queue.push(ticket_url(File.basename(link["href"])))
          end
        end

        true
      end
    end
    MemoryBugs::Crawler.register(Postgres)
  end
end
