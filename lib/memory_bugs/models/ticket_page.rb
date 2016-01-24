require 'digest/sha2'
require 'hashie'

module MemoryBugs
  module Models
    class TicketPage < Hashie::Mash
      def id
        Digest::SHA256.hexdigest(url)[0..30]
      end

      def self.type_name
        :ticket_page
      end

      def self.mapping
        {
          type_name => {
            properties: {
              created_at: { type: 'date' },
              content: { type: 'string' },
              site: { type: 'string', index: 'not_analyzed' },
              url: { type: 'string', index: 'not_analyzed' },
              scraped: { type: 'boolean' },
              error_status: { type: 'integer' }
            }
          }
        }
      end
    end
  end
end
