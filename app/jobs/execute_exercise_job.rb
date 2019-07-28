require 'open3'
require 'rest-client'
require 'nokogiri'
require_relative 'application_job'


class ExecuteExerciseJob < ApplicationJob
  @queue = :plugin_java_execute

  include Utils

  RESULT_URL = "#{::RESULT_SERVICE_URL}/results".freeze

  def self.perform(exercise_id, submission_id, token)
    LOGGER.debug "Starting execution of exercise #{exercise_id} and submission #{submission_id}"

    prepare_execution_environment
    download exercise_id, submission_id, token

    test_path = execution_directory ApplicationJob::TEST_FILENAME
    hidden_test_path = execution_directory ApplicationJob::HIDDEN_TEST_FILENAME
    submission_path = execution_directory ApplicationJob::SUBMISSION_FILENAME

    payload = execute_exercise test_path, hidden_test_path, submission_path

    # Add exercise_id and submission_id to every result
    payload[:result].each do |result|
      result['exercise_id'] = exercise_id
      result['submission_id'] = submission_id
    end

    RestClient.post RESULT_URL, payload
    LOGGER.debug "finished execution of exercise #{exercise_id} and submission #{submission_id}"
  end

  private

  def self.execute_exercise(test_jar_path, hidden_test_jar_path, submission_jar_path)
    # It is important to unzip submission first. This way we make sure that the submission doesn't overwrite any given tests.
    unzip_file submission_jar_path, execution_directory('src', 'test', 'java')
    unzip_file test_jar_path, execution_directory('src', 'test', 'java')
    unzip_file hidden_test_jar_path, execution_directory('src', 'test', 'java')

    _, output, error, pid = run_gradle_task 'test'
    exit_status = pid.value

    unless exit_status.success?
      puts output.read
      puts error.read
      raise "There was an error Executing job for exercise_id: #{exercise_id}, submission_id: #{submission_id}"
    end

    result_paths = Dir["#{execution_directory 'build', 'test-results', 'test'}/*.xml"]
    parse_results(result_paths)
  end

  def self.download(exercise_id, submission_id, token)
    download_submission(token, submission_id, ApplicationJob::SUBMISSION_FILENAME)
    download_exercise(token, exercise_id, ApplicationJob::TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, ApplicationJob::HIDDEN_TEST_FILENAME)
  end

  def self.parse_results(result_paths)
    results = []

    result_paths.each do |result_path|
      result_document = Nokogiri.XML open(result_path)
      result_document.css('testcase').each do |testcase_node|
        result = testcase_node.attributes
        result = result.transform_values(&:value)
  
        if testcase_node.elements.empty?
          result['status'] = :success
        else
          failure_node = testcase_node.first_element_child
          #TODO distinguish more cases
          result['status'] = :failure
          result['failure_message'] = failure_node['message']
          result['failure_type'] = failure_node['type']
          result['failure_details'] = failure_node.text
        end
  
        results << result
      end
    end

    {
        result: results
    }
  end
end
