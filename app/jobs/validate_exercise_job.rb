class ValidateExerciseJob
  include Utils

  VALIDATION_SUCCEEDED = :succeeded
  VALIDATION_FAILED = :failed

  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze
  STUB_FILENAME = 'stub.jar'.freeze

  EXERCISE_UPDATE_URL = "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercises"

  def self.perform(exercise_id, token)
    general_validation_error = nil
    general_validation_error_details = nil

    prepare_execution_environment

    download_exercise(token, exercise_id, TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, HIDDEN_TEST_FILENAME)
    download_exercise_stub(token, exercise_id, STUB_FILENAME)

    stub_validation_error = validate_jar execution_directory(STUB_FILENAME), execution_directory('stub')
    test_validation_error = validate_jar execution_directory(TEST_FILENAME), execution_directory('test')
    hidden_test_validation_error = validate_jar execution_directory(HIDDEN_TEST_FILENAME), execution_directory('hidden_test')

    unzip_file execution_directory(TEST_FILENAME), execution_directory('src', 'test', 'java')
    unzip_file execution_directory(HIDDEN_TEST_FILENAME), execution_directory('src', 'test', 'java')
    _, output, error, pid = run_gradle_task 'compileTestJava'
    exit_status = pid.value

    if exit_status.success?
      general_validation_error = I18n.t 'validation.test_compiles_without_submission'
      general_validation_error_details = output.read + "\n" + error.read
    else
      unzip_file execution_directory(STUB_FILENAME), execution_directory('src', 'test', 'java')

      _, output, error, pid = run_gradle_task 'compileTestJava'
      exit_status = pid.value

      unless exit_status.success?
        general_validation_error = I18n.t "validation.test_doesnt_compile"
        general_validation_error_details = output.read + "\n" + error.read
      end
    end

    validation_succeeded = test_validation_error.nil? &&
        hidden_test_validation_error.nil? &&
        stub_validation_error.nil? &&
        general_validation_error.nil? &&
        general_validation_error_details.nil?

    payload = {
        api_v1_exercise: {
          validation_status: validation_succeeded ? VALIDATION_SUCCEEDED : VALIDATION_FAILED,
          test_validation_error: test_validation_error,
          hidden_test_validation_error: hidden_test_validation_error,
          stub_validation_error: stub_validation_error,
          general_validation_error: general_validation_error,
          general_validation_error_details: general_validation_error_details
        }
    }
    RestClient.patch "#{EXERCISE_UPDATE_URL}/#{exercise_id}", payload
  end
end
