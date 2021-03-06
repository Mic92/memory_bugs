module MemoryBugs
  module Pagination
    def self.included(base)
      base.extend(ClassMethods)
      base.page_limit = 1.0/0.0 # infinity
    end
    module ClassMethods
      def with_page_limit(limit)
        @page_limit = limit
        self
      end
      attr_accessor :page_limit
    end

    def paginate(per_page, &blk)
      (1..(self.class.page_limit)).each do |page|
        yield paged_url(page * per_page)
      end
    end
  end
end
