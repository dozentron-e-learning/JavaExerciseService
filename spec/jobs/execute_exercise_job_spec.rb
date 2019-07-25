require 'rails_helper'

RSpec.describe ExecuteExerciseJob, type: :job do
  before(:each) do
    # Clear Execution Environment before each test
    TestHelper.prepare_execution_environment
  end

  let(:exercise_id) { 1 }
  let(:submission_id) { 2 }
  let(:token) { '' }

  let(:exercise_test_download_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercises/#{exercise_id}/download" }
  let(:exercise_hidden_test_download_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercises/#{exercise_id}/download_hidden" }
  let(:submission_download_url) { "#{Rails.configuration.service_urls.submission_service}/submissions/#{submission_id}/download" }
  let(:result_url) { "#{Rails.configuration.service_urls.result_service}/results" }

  let(:test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'test.jar') }
  let(:hidden_test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'hidden_test.jar') }
  let(:submission_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'submission.jar') }
  let(:submission_failure_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'submission_failure.jar') }

  let(:test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download')) }
  let(:hidden_test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download')) }
  let(:submission_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_download')) }

  describe 'perform' do
    context 'valid test and submission' do
      before do
        stub_request(:get, exercise_test_download_url).to_return(test_response)
        stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)
        stub_request(:get, submission_download_url).to_return(submission_response)

        stub_request(:post, result_url).to_return(status: 200)

        ExecuteExerciseJob.perform exercise_id, submission_id, token
      end

      it('should have downloaded the submission')                   { expect(WebMock).to have_requested(:get, submission_download_url).once }
      it('should have downloaded the test')                         { expect(WebMock).to have_requested(:get, exercise_test_download_url).once }
      it('should have downloaded the hidden_test')                  { expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once }

      it('should have made a post request to create the results')   { expect(WebMock).to have_requested(:post, result_url).once }
    end
  end

  describe 'execute_exercise' do
    context 'all success' do
      let(:expected) { YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'success.yml') }
      let(:result) { ExecuteExerciseJob.execute_exercise test_jar_path, hidden_test_jar_path, submission_jar_path }

      it('should have result grouped as submission') { expect(result).to include(:result)}
      it('should have 5 results') { expect(result[:result].count).to eql(5) }
      it('should all be successes') { expect(result[:result]).to all(include('status' => :success))}
      it('should all be of CalculatorTests') { expect(result[:result]).to all(include('classname' => 'com.example.project.CalculatorTests'))}
      it('should all have time') { expect(result[:result]).to all(include('time'))}
      it('should all have name') { expect(result[:result]).to all(include('name'))}
    end

    context 'all failure' do
      let(:failed_expected) { YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'failed.yml') }
      let(:failed_result) { ExecuteExerciseJob.execute_exercise test_jar_path, hidden_test_jar_path, submission_failure_jar_path }

      it('should have result grouped as submission') { expect(failed_result).to include(:result)}
      it('should have 5 results') { expect(failed_result[:result].count).to eql(5) }
      it('should all be failure') { expect(failed_result[:result]).to all(include('status' => :failure))}
      it('should all be of CalculatorTests') { expect(failed_result[:result]).to all(include('classname' => 'com.example.project.CalculatorTests'))}
      it('should all have time') { expect(failed_result[:result]).to all(include('time'))}
      it('should all have name') { expect(failed_result[:result]).to all(include('name'))}

      it('should all have failure_type') { expect(failed_result[:result]).to all(include('failure_type'))}
      it('should all have failure_message') { expect(failed_result[:result]).to all(include('failure_message'))}
      it('should all have failure_details') { expect(failed_result[:result]).to all(include('failure_details'))}
    end
  end

  describe 'parse_results' do
    context 'only successful' do
      let(:result_paths) { [Rails.root.join('spec', 'resources', 'example_test_report', 'report.xml').to_s] }
      let(:expected) { YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'success.yml') }

      it 'should collect results correctly' do
        expect(ExecuteExerciseJob.parse_results result_paths).to eql(expected)
      end
    end

    context 'only failed' do
      let(:failed_result_paths) { [Rails.root.join('spec', 'resources', 'example_test_report', 'failed_report.xml').to_s] }
      let(:expected) { YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'failed.yml') }

      it 'should collect results correctly' do
        expect(ExecuteExerciseJob.parse_results failed_result_paths).to eql(expected)
      end
    end
  end
end
