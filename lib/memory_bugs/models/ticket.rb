require 'digest/sha2'
require 'hashie'

module MemoryBugs
  module Models
    class Ticket < Hashie::Mash
      include Hashie::Extensions::Coercion

      def id
        Digest::SHA256.hexdigest(url)[0..30]
      end

      def self.type_name
        :ticket
      end

      date_field = ->(v) do
        case v
        when String
          Time.parse(v)
        else
          v
        end
      end

      coerce_key :created_at, date_field
      coerce_key :updated_at, date_field

      def self.mapping
        string = { type: 'string', index: 'not_analyzed' }
        text = { type: 'string' }
        date = { type: 'date' }

        {
          type_name => {
            properties: {
              created_at:  date,
              updated_at:  date,
              title:       text,
              description: text,
              comments:    text,
              external_id: string,
              subsystem:   string,
              priority:    string,
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
