require 'yaml'
require_relative 'printer'

class Config
  @config = nil
  PATH='config.yml'
  # Load configuration from file
  def Config.load(hsh)
    if @config.nil?
      @config = YAML.load_file hsh[:filename]
      Printer::debug(msg:"Config file was found at #{@filename}",who:"Config")
    end
  end
  def Config.[] (section)
    return @config[section]
  end
end

Config.load filename: Config::PATH