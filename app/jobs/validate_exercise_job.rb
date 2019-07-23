class ValidateExerciseJob
  include Utils

  @queue = :plugin_java

  VALIDATION_SUCCEEDED = :success
  VALIDATION_FAILED = :failed

  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze
  STUB_FILENAME = 'stub.jar'.freeze

  EXERCISE_UPDATE_URL = "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise"

  def self.perform(exercise_id, token)
    prepare_execution_environment

    download_exercise(token, exercise_id, TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, HIDDEN_TEST_FILENAME)
    download_exercise_stub(token, exercise_id, STUB_FILENAME)

    payload = validate_exercise(execution_directory(TEST_FILENAME), execution_directory(HIDDEN_TEST_FILENAME), execution_directory(STUB_FILENAME))
    RestClient.patch "#{EXERCISE_UPDATE_URL}/#{exercise_id}", payload
  end

  def self.validate_exercise(test_path, hidden_test_path, stub_path)
    tests = {}

    general_validation_error = nil
    general_validation_error_details = nil

    could_compile_when_should = false

    test_validation_error = validate_jar_content test_path, execution_directory('test')
    hidden_test_validation_error = validate_jar_content hidden_test_path, execution_directory('hidden_test')
    stub_validation_error = validate_jar_content stub_path, execution_directory('stub')

    unzip_file test_path, execution_directory('src', 'test', 'java')
    unzip_file hidden_test_path, execution_directory('src', 'test', 'java')

    could_compile_when_should_not, output, error = compiles?

    if could_compile_when_should_not
      general_validation_error = I18n.t 'validation.test_compiles_without_submission'
      general_validation_error_details = output.read + "\n" + error.read
    else
      unzip_file stub_path, execution_directory('src', 'test', 'java')
      could_compile_when_should, output, error = compiles?

      unless could_compile_when_should
        general_validation_error = I18n.t "validation.test_doesnt_compile"
        general_validation_error_details = output.read + "\n" + error.read
      end
    end

    if could_compile_when_should
      t = find_test_cases

      # Construct Hash:
      # tests = {
      #   test_class: [<test_cases>],
      #   test_class2: ...
      # }
      t.each do |test|
        test_class, test_case = *test
        tests[test_class] = tests[test_class] || []
        tests[test_class] << test_case unless test_case.nil?
      end

      unless tests.any?
        test_validation_error = I18n.t 'validation.test_doesnt_contain_any_tests'
        general_validation_error = I18n.t 'validation.test_doesnt_contain_any_test_disclaimer'
      end

    end

    validation_succeeded = test_validation_error.nil?
    validation_succeeded &&= hidden_test_validation_error.nil?
    validation_succeeded &&= stub_validation_error.nil?
    validation_succeeded &&= general_validation_error.nil?
    validation_succeeded &&= general_validation_error_details.nil?

    {
        api_v1_exercise: {
            tests: tests,

            validation_status: validation_succeeded ? VALIDATION_SUCCEEDED : VALIDATION_FAILED,
            test_validation_error: test_validation_error,
            hidden_test_validation_error: hidden_test_validation_error,
            stub_validation_error: stub_validation_error,
            general_validation_error: general_validation_error,
            general_validation_error_details: general_validation_error_details
        }
    }
  end
end
