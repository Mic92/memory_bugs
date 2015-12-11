require 'memory_bugs/sites/github'

module MemoryBugs
  module Sites
    class Virtuosu
      include MemoryBugs::Sites::Github
      def github_user; "openlink"; end
      def repo_name; "virtuoso-opensource"; end
    end
    MemoryBugs::Crawler.register(Virtuosu)
  end
end
