require 'ostruct'

module MemoryBugs
  Config = OpenStruct.new
  def load_config
    env = ENV["environment"] || "production"
    root = File.dirname(File.expand_path(__FILE__, "../.."))

    config_path = File.join(root, "config.yml")
    config = YAML.load_file(config_path).deep_symbolize_keys
    if config[env]
      config[env].each do |k,v|
        Config[k] = v
      end
    end
    Config.env = env
    Config.root = root
  end
end

MemoryBugs.load_config
