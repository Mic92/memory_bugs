module MemoryBugs
  module Scrapers
    class Postgres
      def process(content)
        doc = Nokogiri::HTML(content)

        messages = doc.css("#pgContentWrap .msgwrap")
        issue = messages[0]
        rows = issue.css(".message td")
        match = /BUG #(?<id>\d+): (?<title>.+)/.match(rows[2])
        body = issue.css(".bodywrapper").text
        match2 = /^Description: (?<desc>.*)/m.match(body)

        comments = []
        doc.css("#pgContentWrap .msgwrap .bodywrapper").each_with_index do |bodies, i|
          next if i == 0
          comments << Helpers::clean_text(bodies.text)
        end

        ticket = MemoryBugs::Models::Ticket.new
        ticket.title = Helpers::clean_text(match[:title])
        ticket.external_id = match[:id].strip
        ticket.created_at = Time.parse(rows[3].text.strip)
        ticket.description = match2[:desc].strip
        unless comments.empty?
          ticket.comments = comments.join("\n")
        end
        [ticket]
      end
    end
    MemoryBugs::Scraper.register(Postgres)
  end
end
