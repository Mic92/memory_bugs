require 'memory_bugs/sites/github'

module MemoryBugs
  module Sites
    class Leveldb
      include MemoryBugs::Sites::Github
      def github_user; "google"; end
      def repo_name; "leveldb"; end
    end
    MemoryBugs::Crawler.register(Leveldb)
  end
end
