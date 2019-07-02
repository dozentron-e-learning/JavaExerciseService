require 'rails_helper'

RSpec.describe ExecuteExerciseJob, type: :job do
  describe 'perform' do
    it 'fails right now' do
      submission_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_download'))
      test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download'))
      hidden_test_response = File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download'))
      stub_request(:get, 'http://localhost:3001/api/v1/submission/1/download').to_return(submission_response)
      stub_request(:get, 'http://localhost:3000/api/v1/exercise/1/download').to_return(test_response)
      stub_request(:get, 'http://localhost:3000/api/v1/exercise/1/download_hidden').to_return(hidden_test_response)

      ExecuteExerciseJob.perform 1, 1, ''

      throw 'fail'
    end
  end
end
