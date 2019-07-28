require_relative 'application_job'

class ValidateSubmissionJob < ApplicationJob
  @queue = :plugin_java_validate

  VALIDATION_SUCCEEDED = :success
  VALIDATION_FAILED = :failed

  SUBMISSION_UPDATE_URL = "#{::SUBMISSION_SERVICE_URL}/submissions"

  def self.perform(exercise_id, submission_id, token)
    LOGGER.debug "Starting validation of submission #{submission_id} with exercise #{exercise_id}"

    prepare_execution_environment

    download_exercise(token, exercise_id, ApplicationJob::TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, ApplicationJob::HIDDEN_TEST_FILENAME)

    download_submission(token, submission_id, ApplicationJob::SUBMISSION_FILENAME)

    payload = validate_submission(
        execution_directory(ApplicationJob::TEST_FILENAME),
        execution_directory(ApplicationJob::HIDDEN_TEST_FILENAME),
        execution_directory(ApplicationJob::SUBMISSION_FILENAME))

    RestClient.patch "#{SUBMISSION_UPDATE_URL}/#{submission_id}", payload
    LOGGER.debug "finished validation of submission #{submission_id} with exercise #{exercise_id}"
  end

  def self.validate_submission(test_path, hidden_test_path, submission_path)
    general_validation_error = nil
    general_validation_error_details = nil

    submission_validation_error = validate_jar_content submission_path, execution_directory('stub')

    unzip_file submission_path, execution_directory('src', 'test', 'java')
    unzip_file test_path, execution_directory('src', 'test', 'java')
    unzip_file hidden_test_path, execution_directory('src', 'test', 'java')
    _, output, error, pid = run_gradle_task 'compileTestJava'
    exit_status = pid.value

    unless exit_status.success?
      general_validation_error = I18n.t 'validation.submission_doesnt_compile'
      general_validation_error_details = output.read + "\n" + error.read
    end

    validation_succeeded = submission_validation_error.nil?
    validation_succeeded &&= general_validation_error.nil?
    validation_succeeded &&= general_validation_error_details.nil?

    {
        submission: {
            validation_status: validation_succeeded ? VALIDATION_SUCCEEDED : VALIDATION_FAILED,
            file_validation_error: submission_validation_error,
            general_validation_error: general_validation_error,
            general_validation_error_details: general_validation_error_details
        }
    }
  end
end
