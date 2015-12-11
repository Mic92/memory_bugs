require 'json'
require 'memory_bugs/sites/github'

module MemoryBugs
  module Sites
    class Redis
      include MemoryBugs::Sites::Github
      def github_user; "antirez"; end
      def repo_name; "redis"; end
    end
    MemoryBugs::Crawler.register(Redis)
  end
end
