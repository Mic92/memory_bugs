module MemoryBugs
  class Request
    def initialize(url, headers: {})
      @url = url
      @headers = headers
    end
    attr_reader :url, :headers
  end
end
