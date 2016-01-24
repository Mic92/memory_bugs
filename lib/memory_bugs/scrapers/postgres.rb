module MemoryBugs
  module Scrapers
    class Postgres
      def parse_header(ticket, row)
        value = row.css("td").text.strip
        case row.css("th").text
        when /subject/i
          match = /BUG #(?<id>\d+)(: (?<title>.+))?/.match(value)
          ticket.external_id = match[:id]
          if match[:title]
            ticket.title = match[:title].strip
          end
        when /date/i
          ticket.created_at = value
        end
      end

      def process(content)
        doc = Nokogiri::HTML(content)

        messages = doc.css("#pgContentWrap .msgwrap")
        issue = messages[0]
        ticket = MemoryBugs::Models::Ticket.new
        rows = issue.css(".message tr")
        rows.each { |row| parse_header(ticket, row) }
        body = issue.css(".bodywrapper").text
        match2 = /^Description: (?<desc>.*)/m.match(body)
        description = if match2
          match2[:desc]
        else
          body
        end

        comments = []
        doc.css("#pgContentWrap .msgwrap .bodywrapper").each_with_index do |bodies, i|
          next if i == 0
          comments << Helpers::clean_text(bodies.text)
        end

        ticket.description = Helpers::clean_text(description)

        unless comments.empty?
          ticket.comments = comments.join("\n")
        end
        [ticket]
      end
    end
    MemoryBugs::Scraper.register(Postgres)
  end
end
