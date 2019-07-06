require 'rails_helper'

RSpec.describe ValidateExerciseJob, type: :job do
  describe 'perform' do
    it 'it runs in general and produces no validation errors with valid tests.' do
      exercise_id = 1

      exercise_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download"
      exercise_hidden_test_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download_hidden"
      exercise_stub_download_url = "http://localhost:3000/api/v1/exercise/#{exercise_id}/download_stub"

      exercise_update_url = "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercises/#{exercise_id}"

      stub_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'stub_download'))
      test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download'))
      hidden_test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download'))

      stub_request(:get, exercise_test_download_url).to_return(test_response)
      stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)
      stub_request(:get, exercise_stub_download_url).to_return(stub_response)

      stub_request(:patch, exercise_update_url).to_return(status: 200)

      ValidateExerciseJob.perform exercise_id, ''

      expect(WebMock).to have_requested(:get, exercise_stub_download_url).once
      expect(WebMock).to have_requested(:get, exercise_test_download_url).once
      expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once

      expect(WebMock).to have_requested(:patch, exercise_update_url)
                             # .with(body: hash_including({
                             #     "api_v1_exercise[validation_status]" => 'succeeded',
                             #     "api_v1_exercise[test_validation_error]" => nil,
                             #     "api_v1_exercise[hidden_test_validation_error]" => nil,
                             #     "api_v1_exercise[stub_validation_error]" => nil,
                             #     "api_v1_exercise[general_validation_error]" => nil,
                             #     "api_v1_exercise[general_validation_error_details]" => nil
                             # }))

      stub_response.close
      test_response.close
      hidden_test_response.close
    end
  end
end
