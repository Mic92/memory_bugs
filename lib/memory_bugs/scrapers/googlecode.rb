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
        updated_at = container.css(".issuecomment .date").last["title"]
        comments = container.css(".issuecomment pre").map do |comment|
          comment.text.strip
        end
        metalables = doc.css("#issuemeta .label")
        type = metalables[0].text.strip.gsub(/Type-/, "")
        priority = metalables[1].text.strip.gsub(/Priority-/, "")

        ticket = MemoryBugs::Models::Ticket.new
        ticket.title = title
        ticket.external_id = id
        ticket.description = desc
        ticket.comments = comments.join("\n")
        ticket.created_at = Time.parse(created_at)
        ticket.updated_at = Time.parse(updated_at)
        ticket.type = type
        ticket.priority = priority

        [ticket]
      end
    end
  end
end
