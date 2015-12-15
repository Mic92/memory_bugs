module MemoryBugs
  module Scrapers
    module Jira
      def parse_detail(ticket, detail)
        name = detail.css(".name").text
        value = detail.css(".value").text.strip
        case name.downcase
        when /type/
          ticket.type = value.downcase
        when /priority/
          ticket.priority = value.downcase
        when /affects version/
          ticket.version = Helpers::clean_text(value)
        when /status/
          ticket.status = value.downcase
        when /resolution/
          ticket.resolution = value.downcase
        when /reproduce/
          ticket.description = Helpers::clean_text(value)
        end
      end

      def process(content)
        doc = Nokogiri::HTML(content)
        issue = doc.css(".issue-body-content")
        details = issue.css("#details-module .item")
        ticket = MemoryBugs::Models::Ticket.new
        details.each do |detail|
          parse_detail(ticket, detail)
        end
        desc = issue.css(".description-val .user-content-block").text
        if ticket.description.nil?
          ticket.description = Helpers.clean_text(desc)
        else
          ticket.description += "\n" + Helpers.clean_text(desc)
        end

        [ticket]
      end
    end
  end
end
