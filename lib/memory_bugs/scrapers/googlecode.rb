module MemoryBugs
  module Scrapers
    module Googlecode
      def process(content)
        doc = Nokogiri::HTML(content)
        header = doc.css("#issueheader")
        id = header.css(".h3 a").text.strip
        title = header.css("td.vt:nth-child(2)").text.strip
        container = doc.css("#meta-container")
        desc = container.css(".issuedescription pre").text.strip
        created_at = container.css(".issuedescription .date").first["title"]
        comment_dates = container.css(".issuecomment .date")
        if comment_dates.empty?
          updated_at = created_at
        else
          updated_at = container.css(".issuecomment .date").last["title"]
        end
        comments = container.css(".issuecomment pre").map do |comment|
          comment.text.strip
        end

        ticket = MemoryBugs::Models::Ticket.new
        doc.css("#issuemeta .label").each do |row|
          case row.text
          when /Type-(\w+)/
            ticket.type = $1
          when /Priority-(\w+)/
            ticket.priority = $1
          end
        end
        doc.css("#issuemeta #meta-float tr").each do |row|
          if row.css("th").text =~ /Status/
            ticket.status = Helpers::clean_text(row.css("td").text.downcase)
          end
        end

        ticket.title = title
        ticket.external_id = id
        ticket.description = desc
        ticket.comments = comments.join("\n")
        ticket.created_at = created_at
        ticket.updated_at = updated_at

        [ticket]
      end
    end
  end
end
