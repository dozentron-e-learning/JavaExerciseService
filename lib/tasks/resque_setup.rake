require_relative '../../config/initializers/setup_service_urls'
require_relative '../../app/jobs/../../app/jobs/validate_exercise_job'
require_relative '../../app/jobs/../../app/jobs/../../app/jobs/validate_submission_job'
require_relative '../../app/jobs/../../app/jobs/../../app/jobs/execute_exercise_job'

task "resque:setup" do
  require_relative '../../config/initializers/resque_configuration'
  require 'i18n'

  # If we are not running in a rails context we need to setup i18n support
  unless defined? Rails
    I18n.load_path << Dir[File.expand_path("config/locales") + "/*.yml"]
    I18n.default_locale = :en # (note that `en` is already the default!)
  end
end