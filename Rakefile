$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'rake/testtask'
require 'memory_bugs'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

namespace :crawler do
  desc "Find tickets"
  task :find do
    crawler = MemoryBugs::Crawler.new
    crawler.find_tickets
  end

  desc "Download tickets"
  task :download do
    crawler = MemoryBugs::Crawler.new
    crawler.download_tickets
  end
end

namespace :scraper do
  desc "Process tickets"
  task :process do
    scraper = MemoryBugs::Scraper.new
    scraper.process_tickets
  end

  desc "Reset tickets"
  task :reset do
    k = MemoryBugs::Models::TicketPage
    pages = []
    MemoryBugs::Elasticsearch.scroll(k) do |page|
      pages << MemoryBugs::Models::TicketPage.new(url: page.url,
                                                  scraped: false)
      if pages.size > 1000
        MemoryBugs::Elasticsearch.bulk(pages)
        pages.clear
      end
    end
    unless pages.empty?
      MemoryBugs::Elasticsearch.bulk(pages)
    end
  end
end

namespace :elasticsearch do
  desc "Create elasticsearch mapping"
  task :create_mapping do
    MemoryBugs::Elasticsearch.create_mapping
  end
end
