# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application' if defined? Rails
require 'resque/tasks'
load 'lib/tasks/resque_setup.rake'

Rails.application.load_tasks if defined? Rails
