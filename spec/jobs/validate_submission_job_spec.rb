require 'rails_helper'

RSpec.describe ValidateSubmissionJob, type: :job do
  before(:each) do
    # Clear Execution Environment before each test
    TestHelper.prepare_execution_environment
  end

  describe 'perform' do
    it 'it runs in general and produces no validation errors with valid submissions.' do
      exercise_id = 1
      submission_id = 2

      exercise_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download"
      exercise_hidden_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download_hidden"
      submission_download_url = "http://localhost:3001/submission/#{submission_id}/download"

      submission_update_url = "#{Rails.configuration.service_urls.submission_service}/submission/#{submission_id}"

      test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download'))
      hidden_test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download'))
      submission_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_download'))

      stub_request(:get, exercise_test_download_url).to_return(test_response)
      stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)
      stub_request(:get, submission_download_url).to_return(submission_response)

      stub_request(:patch, submission_update_url).to_return(status: 200)

      ValidateSubmissionJob.perform exercise_id, submission_id, ''

      expect(WebMock).to have_requested(:get, submission_download_url).once
      expect(WebMock).to have_requested(:get, exercise_test_download_url).once
      expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once

      expect(WebMock).to have_requested(:patch, submission_update_url)
      # .with(body: hash_including({
      #     "api_v1_exercise[validation_status]" => 'succeeded',
      #     "api_v1_exercise[test_validation_error]" => nil,
      #     "api_v1_exercise[hidden_test_validation_error]" => nil,
      #     "api_v1_exercise[stub_validation_error]" => nil,
      #     "api_v1_exercise[general_validation_error]" => nil,
      #     "api_v1_exercise[general_validation_error_details]" => nil
      # }))

      submission_response.close
      test_response.close
      hidden_test_response.close
    end
  end

  describe 'validate_exercise' do
    it 'it recognizes compilation problems' do
      test_path = Rails.root.join 'spec', 'resources', 'jars', 'test.jar'

      result = ValidateSubmissionJob.validate_submission test_path, test_path, test_path

      expect(result[:submission]).to include(
          :general_validation_error_details,
          validation_status: :failed,
          file_validation_error: nil,
          general_validation_error: I18n.t('validation.submission_doesnt_compile')
      )
    end
  end
end
