module MemoryBugs
  module Sites
    module Github
      def github_user
        raise StandardError.new("Must be overwritten")
      end

      def repo_name
        raise StandardError.new("Must be overwritten")
      end

      def seed_url
        "https://api.github.com/repos/#{github_user}/#{repo_name}/issues"
      end

      def ticket_url(number)
        "https://github.com/#{github_user}/#{repo_name}/issues/#{number}"
      end

      def process(url, content, ticket_queue)
        issues = JSON.parse(content)
        number = issues[0]["number"]
        headers = { "X-GitHub-Media-Type" => "github.v3; param=full; format=json" }
        number.times do |n|
          request = Typhoeus::Request.new(ticket_url(n + 1), headers: headers)
          ticket_queue.push(request)
        end
      end
    end
  end
end
