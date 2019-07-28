require 'pathname'
require 'yaml'
require 'erb'

rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'

service_url_config = YAML::load(ERB.new(IO.read(rails_root + '/config/service_urls.yml')).result)
config = service_url_config[rails_env]

EXERCISE_SERVICE_URL = config['exercise_service']
SUBMISSION_SERVICE_URL = config['submission_service']
RESULT_SERVICE_URL = config['result_service']

WORKER_ROOT_PATH = Pathname.new rails_root