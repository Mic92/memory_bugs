$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rake/testtask'
require 'memory_bugs/elasticsearch'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

namespace :elasticsearch do
  desc "Create elasticsearch mapping"
  task :create_mapping do
    MemoryBugs::Elasticsearch.create_mapping
  end
end
