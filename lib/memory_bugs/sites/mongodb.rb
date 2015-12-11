require 'memory_bugs/sites/jira'

module MemoryBugs
  module Sites
    class Mongodb
      include MemoryBugs::Sites::Jira
      def site; "https://jira.mongodb.org"; end
      def project; "SERVER"; end
    end

    MemoryBugs::Crawler.register(Mongodb)
  end
end
