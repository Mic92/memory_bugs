#require 'memory_bugs/sites/jira'
#
#module MemoryBugs
#  module Sites
#    class Firebird
#      include MemoryBugs::Sites::Jira
#      def site; "http://tracker.firebirdsql.org"; end
#      def project; "CORE"; end
#    end
#
#    MemoryBugs::Crawler.register(Firebird)
#  end
#end
