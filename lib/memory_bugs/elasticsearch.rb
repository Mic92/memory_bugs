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

      def serialize(obj)
        hash = obj.to_h
        hash.each do |k,v|
          if v.is_a?(Time)
            hash[k] = v.iso8601
          end
        end
        hash
      end

      def bulk(objects)
        updates = objects.map do |object|
          {
            update: {
              _index: index_name,
              _type:  object.class.type_name,
              _id: object.id,
              data: {
                doc: serialize(object),
                doc_as_upsert: true
              }
            }
          }
        end
        res = Client.bulk(body: updates)
        raise "bulk exited with errors" if res["errors"] == true
        res
      end

      def scroll(klass, search: {})
        args = {
          index: index_name,
          type: klass.type_name,
          search_type: 'scan',
          scroll: '1m',
          size: 1000
        }.merge(search)
        response = Client.search(args)

        loop do
          response = Client.scroll(scroll_id: response['_scroll_id'],
                                   scroll: '100m')
          hits = response['hits']['hits']
          break if hits.empty?

          hits.map do |r|
            yield klass.new(r['_source'])
          end
        end
      end
    end
  end
end
