require "memory_bugs/scraper"

sites = %w{sqlite}
sites.each do |site|
  require "memory_bugs/scrapers/#{site}"
end
