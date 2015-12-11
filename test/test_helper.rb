require 'minitest/spec'
require 'minitest/autorun'
require 'vcr'
require 'pathname'

TEST_ROOT = Pathname.new(File.dirname(__FILE__))
$:.unshift TEST_ROOT.parent.join("lib")

def fixture_path(path)
  TEST_ROOT.join("fixtures", path)
end

VCR.configure do |c|
  c.cassette_library_dir = fixture_path('vcr_cassettes')
  c.hook_into :webmock
end

def delete_elasticsearch_index(*klasses)
end
