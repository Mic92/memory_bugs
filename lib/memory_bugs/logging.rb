require 'logger'

module MemoryBugs
  Logger = Logger.new(STDOUT)
  Logger.level = ::Logger::INFO
end
