require 'rails_helper'

RSpec.describe ExecuteExerciseJob, type: :job do
  describe 'perform' do
    it 'it runs in general and produces test results' do
      exercise_id = 1
      submission_id = 2

      submission_download_url = "http://localhost:3001/submission/#{submission_id}/download"
      exercise_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download"
      exercise_hidden_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download_hidden"

      result_url = 'http://localhost:3002/results'

      submission_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_download'))
      test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download'))
      hidden_test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download'))

      stub_request(:get, submission_download_url).to_return(submission_response)
      stub_request(:get, exercise_test_download_url).to_return(test_response)
      stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)

      stub_request(:post, result_url).to_return(status: 200)

      ExecuteExerciseJob.perform exercise_id, submission_id, ''

      expect(WebMock).to have_requested(:get, submission_download_url).once
      expect(WebMock).to have_requested(:get, exercise_test_download_url).once
      expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once

      expect(WebMock).to have_requested(:post, result_url)
      #.with(body: hash_including(exercise_id: exercise_id, submission_id: submission_id))

      submission_response.close
      test_response.close
      hidden_test_response.close
    end

    it 'it can handle test failures and uploaded Junit tests' do
      exercise_id = 1
      submission_id = 2

      submission_download_url = "http://localhost:3001/submission/#{submission_id}/download"
      exercise_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download"
      exercise_hidden_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download_hidden"

      result_url = 'http://localhost:3002/results'

      submission_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_failure_download'))
      test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download'))
      hidden_test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download'))

      stub_request(:get, submission_download_url).to_return(submission_response)
      stub_request(:get, exercise_test_download_url).to_return(test_response)
      stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)

      stub_request(:post, result_url).to_return(status: 200)

      ExecuteExerciseJob.perform exercise_id, submission_id, ''

      expect(WebMock).to have_requested(:get, submission_download_url).once
      expect(WebMock).to have_requested(:get, exercise_test_download_url).once
      expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once

      expect(WebMock).to have_requested(:post, result_url)
      #.with(body: hash_including(exercise_id: exercise_id, submission_id: submission_id))

      submission_response.close
      test_response.close
      hidden_test_response.close
    end
  end
  describe 'collect_results' do
    it 'collects successfull reports' do
      exercise_id = 1
      submission_id = 2
      result_paths = [Rails.root.join('spec', 'resources', 'example_test_report', 'failed_report.xml').to_s]
      expected = YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'failed.yml')

      actual_result = ExecuteExerciseJob.collect_results exercise_id, submission_id, result_paths

      expect(actual_result).to eql(expected)
    end

    it 'collects failed reports' do
      exercise_id = 1
      submission_id = 2
      result_paths = [Rails.root.join('spec', 'resources', 'example_test_report', 'report.xml').to_s]
      expected = YAML.load_file Rails.root.join('spec', 'resources', 'example_test_report', 'success.yml')

      actual_result = ExecuteExerciseJob.collect_results exercise_id, submission_id, result_paths

      expect(actual_result).to eql(expected)
    end
  end
end
