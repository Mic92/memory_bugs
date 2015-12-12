require 'digest/sha2'
require 'hashie'

module MemoryBugs
  module Models
    class Ticket < Hashie::Mash
      def id
        Digest::SHA256.hexdigest(url)[0..30]
      end

      def self.type_name
        :ticket
      end

      def self.mapping
        string = { type: 'string', index: 'not_analyzed' }
        text = { type: 'string' }
        date = { type: 'date' }

        {
          type_name => {
            properties: {
              _all: { enabled: false },
              created_at:  date,
              updated_at:  date,
              title:       text,
              description: text,
              comments:    text,
              external_id: string,
              subsystem:   string,
              priority:    string,
              serverty:    string,
              version:     string,
              type:        string,
              status:      string,
              url:         string,
            }
          }
        }
      end
    end
  end
end
