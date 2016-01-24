module MemoryBugs
  module Scrapers
    module Github
      def process(content)
        doc = Nokogiri::HTML(content)
        issue = doc.css("#show_issue")
        title = Helpers::clean_text(issue.css(".js-issue-title").text)
        state = issue.css(".state:last-child").text.downcase
        id = issue.css(".gh-header-number").text
        comments = []
        first_comment = nil
        issue.css(".comment").each_with_index do |comment, i|
          text = Helpers::clean_text(comment.css(".comment-body").text)
          if i == 0
            first_comment = text
          else
            comments << text
          end
        end
        times = issue.css("time")
        created_at = times.first["datetime"]
        updated_at = times.last["datetime"]

        ticket = MemoryBugs::Models::Ticket.new
        ticket.title = title
        ticket.description = first_comment
        ticket.created_at = Time.parse(created_at)
        ticket.updated_at = Time.parse(updated_at)
        ticket.external_id = id
        ticket.status = Helpers::clean_text(state)
        ticket.comments = comments.join("\n")

        [ticket]
      end
    end
  end
end
