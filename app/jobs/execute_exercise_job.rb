require 'open3'

class ExecuteExerciseJob
  include Utils

  SUBMISSION_FILENAME = 'submission.jar'.freeze
  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze

  def self.perform(exercise_id, submission_id, token)
    prepare_execution_environment

    download_submission(token, submission_id, SUBMISSION_FILENAME)
    unzip_file execution_directory(SUBMISSION_FILENAME), execution_directory('src', 'main', 'java')

    download_exercise(token, exercise_id, TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, HIDDEN_TEST_FILENAME)

    unzip_file execution_directory(TEST_FILENAME), execution_directory('src', 'test', 'java')
    unzip_file execution_directory(HIDDEN_TEST_FILENAME), execution_directory('src', 'test', 'java')

    input, output, error, pid = ::Open3.popen3('gradle test', chdir: execution_directory)
    exit_status = pid.value

    unless exit_status.success?
      puts output.read
      puts error.read
      raise "There was an error Executing job for exercise_id: #{exercise_id}, submission_id: #{submission_id}"
    end


  end
end
