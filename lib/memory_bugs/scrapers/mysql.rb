module MemoryBugs
  module Scrapers
    class Mysql
      def assign_field(ticket, label, value)
        case label
        when /bug\S#(\d+)/
          ticket.title = value.strip
          ticket.external_id = $1
        when /submitted/
          ticket.created_at = value
        when /modified/
          ticket.updated_at = value
        when /status/
          ticket.status = Helpers::clean_text(value.downcase)
        when /category/
          ticket.subsystem = value
        when /^version/
          ticket.version = value
        when /severity/
          ticket.priority = value.downcase
        end
      end

      def process(content)
        doc = Nokogiri::HTML(content)
        ticket = MemoryBugs::Models::Ticket.new
        doc.css("#bugheader tr").each do |row|
          values = row.css("td")
          row.css("th").each_with_index do |label, i|
            assign_field(ticket, label.text.strip.downcase, values[i].text.strip)
          end
        end
        ticket.description = Helpers::clean_text(doc.css("#cmain .note").text)
        comments = doc.css(".comment:not(#cmain) .note").map do |elem|
          Helpers::clean_text(elem.text)
        end
        ticket.comments = comments.join("\n")
        [ticket]
      end
    end
    MemoryBugs::Scraper.register(Mysql)
  end
end
