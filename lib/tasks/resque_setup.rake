require_relative '../../app/jobs/../../app/jobs/validate_exercise_job'
require_relative '../../app/jobs/../../app/jobs/../../app/jobs/validate_submission_job'
require_relative '../../app/jobs/../../app/jobs/../../app/jobs/execute_exercise_job'

task "resque:setup" do
  require_relative '../../config/initializers/resque_configuration'
end