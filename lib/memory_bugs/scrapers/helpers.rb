module MemoryBugs
  module Scrapers
    module Helpers
      def self.clean_text(s)
        s = s.strip
        # whitespace + newline -> single newline
        s.gsub!(/\s*\n\s*/, "\n")
        # multiple instances of whitespace to single space
        s.gsub!(/[\t ]+/, " ")
        s
      end
    end
  end
end
