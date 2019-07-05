require 'open3'
require 'rest-client'
require 'nokogiri'

class ExecuteExerciseJob
  include Utils

  RESULT_URL = "#{Rails.configuration.service_urls.results_service}/results"

  SUBMISSION_FILENAME = 'submission.jar'.freeze
  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze

  def self.perform(exercise_id, submission_id, token)
    prepare exercise_id, submission_id, token
    _, output, error, pid = ::Open3.popen3('./gradlew test', chdir: execution_directory)
    exit_status = pid.value

    unless exit_status.success?
      puts output.read
      puts error.read
      raise "There was an error Executing job for exercise_id: #{exercise_id}, submission_id: #{submission_id}"
    end

    send_results(exercise_id, submission_id, token)
  end

  private

  def self.prepare(exercise_id, submission_id, token)
    prepare_execution_environment

    download_submission(token, submission_id, SUBMISSION_FILENAME)
    unzip_file execution_directory(SUBMISSION_FILENAME), execution_directory('src', 'main', 'java')

    download_exercise(token, exercise_id, TEST_FILENAME)
    download_exercise_hidden(token, exercise_id, HIDDEN_TEST_FILENAME)

    unzip_file execution_directory(TEST_FILENAME), execution_directory('src', 'test', 'java')
    unzip_file execution_directory(HIDDEN_TEST_FILENAME), execution_directory('src', 'test', 'java')
  end

  def self.send_results(exercise_id, submission_id, token)
    result_paths = Dir["#{execution_directory 'build', 'test-results', 'test'}/*.xml"]
    results = parse_results result_paths
    results.each do |result|
      result['exercise_id'] = exercise_id
      result['submission_id'] = submission_id
    end

    payload = {
        result: results
    }
    RestClient.post RESULT_URL, payload
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

    results
  end
end
