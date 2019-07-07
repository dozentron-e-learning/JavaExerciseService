class ValidateSubmissionJob
  include Utils

  VALIDATION_SUCCEEDED = :succeeded
  VALIDATION_FAILED = :failed

  SUBMISSION_FILENAME = 'submission.jar'.freeze
  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze

  SUBMISSION_UPDATE_URL = "#{Rails.configuration.service_urls.submission_service}/api/v1/exercises"

  def self.perform(exercise_id, submission_id, token)
    prepare_execution_environment

    download_exercise(token, exercise_id, TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, HIDDEN_TEST_FILENAME)

    download_submission(token, submission_id, SUBMISSION_FILENAME)

    payload = validate_submission(execution_directory(TEST_FILENAME), execution_directory(HIDDEN_TEST_FILENAME), execution_directory(SUBMISSION_FILENAME))
    RestClient.patch "#{SUBMISSION_UPDATE_URL}/#{submission_id}", payload
  end

  def self.validate_submission(test_path, hidden_test_path, submission_path)
    general_validation_error = nil
    general_validation_error_details = nil

    submission_validation_error = validate_jar submission_path, execution_directory('stub')

    unzip_file submission_path, execution_directory('src', 'test', 'java')
    unzip_file test_path, execution_directory('src', 'test', 'java')
    unzip_file hidden_test_path, execution_directory('src', 'test', 'java')
    _, output, error, pid = run_gradle_task 'compileTestJava'
    exit_status = pid.value

    if exit_status.failed?
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
