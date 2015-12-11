require 'ostruct'
require 'yaml'
require 'hashie'

module MemoryBugs
  Config = Hashie::Mash.new
  def self.load_config
    env = ENV["environment"] || "production"
    root = File.expand_path(File.join(File.dirname(__FILE__), "../.."))

    config_path = File.join(root, "config.yml")
    yaml = YAML.load_file(config_path)
    if yaml
      Config.deep_merge(yaml)
    end
    Config.env = env
    Config.root = root
  end
end

MemoryBugs.load_config
