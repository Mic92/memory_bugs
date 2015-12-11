require 'memory_bugs/sites/jira'

module MemoryBugs
  module Sites
    class Mariadb
      include MemoryBugs::Sites::Jira
      def site; "https://mariadb.atlassian.net"; end
      def project; "MDEV"; end
    end

    MemoryBugs::Crawler.register(Mariadb)
  end
end
