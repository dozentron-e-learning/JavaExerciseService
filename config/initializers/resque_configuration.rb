require 'pathname'
require 'resque'
require 'yaml'
require 'erb'

LOGGER = Logger.new STDOUT

rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
config_file = rails_root + '/config/resque.yml'

resque_config = YAML::load(ERB.new(IO.read(config_file)).result)
Resque.redis = resque_config[rails_env]

if rails_env == 'development'
  Resque.logger = Logger.new STDOUT
  LOGGER.level= Logger::DEBUG
  Resque.logger.level = Logger::DEBUG
end