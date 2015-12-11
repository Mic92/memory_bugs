require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'elasticsearch'

require 'memory_bugs/config'
require 'memory_bugs/logging'
require 'memory_bugs/models'

module MemoryBugs
  module Elasticsearch
    args = {
      hosts: MemoryBugs::Config.elasticsearch_hosts || ["http://localhost:9200"],
      logger: MemoryBugs::Logger,
      retry_on_failure: 5,
      reload_connections: true
    }
    Client = ::Elasticsearch::Client.new(**args)

    class << self
      def index_name
        config = MemoryBugs::Config
        prefix = @index_prefix || config.env || ""
        index_name = @index_name || config.elasticsearch_index || "memory_bugs"
        "#{prefix}-#{index_name}"
      end

      def create(document)
        Client.create index: self.index_name,
          type: document.class.type_name,
          id: document.id,
          body: document
      end

      def create_mapping
        models = []
        MemoryBugs::Models.constants.select do |c|
          const = MemoryBugs::Models.const_get(c)
          if Class === const && const.respond_to?(:mapping)
            models << const
          end
        end
        mappings = models.inject({}) do |hash, model|
          hash.merge!(model.mapping)
        end

        Client.indices.create(index: index_name, body: { mappings: mappings })
      end

      def delete_index
        Client.indices.delete(index: index_name)
      end

      def count
        Client.count(index: index_name)["count"]
      end

      def refresh
        Client.indices.refresh
      end
    end
  end
end
