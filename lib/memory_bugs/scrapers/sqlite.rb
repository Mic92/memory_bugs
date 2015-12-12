module MemoryBugs
  module Scrapers
    class Sqlite
      def assign_field(ticket, label, value)
        case label
        when /UUID/i
          ticket.external_id = value
        when /title/i
          ticket.title = value
        when /status/i
          ticket.status = value
        when /last modified/i
          ticket.updated_at = Date.parse(value)
        when /type/i
          ticket.type = value
        when /resultion/i
          ticket.resultion = value
        when /priority/i
          ticket.priority = value
        when /version found/i
          ticket.version = value
        when /subsystem/i
          ticket.subsystem = value
        when /user comments/i
        when /\s*/
        else
          puts("unknown label: #{label}")
        end
      end

      def process(page)
        doc = Nokogiri::HTML(page.content)
        ticket = MemoryBugs::Models::Ticket.new

        doc.css(".content table tr").each do |row|
          label = row.css(".tktDspLabel").text
          value = row.css(".tktDspValue").text.strip
          assign_field(ticket, label, value)
        end
        last_row = doc.css(".content table tr:last")
        value = last_row.css(".tktDspValue").text.strip
        ticket.description = value
        match = /added on (?<date>.+):\n/.match(value)
        ticket.created_at = Date.parse(match[:date])

        [ticket]
      end
    end
    MemoryBugs::Scraper.register(Sqlite)
  end
end
