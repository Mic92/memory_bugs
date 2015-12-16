require 'json'

module MemoryBugs
  module Sites
    module Jira
      def self.included(base)
        base.send(:include, MemoryBugs::Pagination)
      end

      def site
        raise StandardError.new("Must be overwritten")
      end

      def project
        raise StandardError.new("Must be overwritten")
      end

      def seed_url; paged_url(0); end
      def per_page; 10000; end

      def paged_url(entries)
        "#{site}/rest/api/latest/search?maxResults=#{per_page}&fields=key&jql=project+%3D+#{project}&startAt=#{entries}"
      end

      def ticket_url(key)
        "#{site}/browse/#{key}"
      end

      def process(url, content, ticket_urls, &blk)
        tickets = JSON.parse(content)["issues"]

        tickets.each do |ticket|
          ticket_urls.push(ticket_url(ticket["key"]))
        end

        paginate(per_page, &blk) if url == seed_url

        tickets.size >= per_page
      end
    end
  end
end
