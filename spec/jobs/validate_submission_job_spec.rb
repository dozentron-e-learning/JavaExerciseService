require 'rails_helper'

RSpec.describe ValidateSubmissionJob, type: :job do
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
  let(:submission_update_url) { "#{Rails.configuration.service_urls.submission_service}/submissions/#{submission_id}" }

  let(:test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'test.jar') }
  let(:hidden_test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'hidden_test.jar') }
  let(:submission_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'submission.jar') }

  let(:test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download')) }
  let(:hidden_test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download')) }
  let(:submission_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'submission_download')) }

  describe 'perform' do
    context 'valid test and submission' do
      before do
        stub_request(:get, exercise_test_download_url).to_return(test_response)
        stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)
        stub_request(:get, submission_download_url).to_return(submission_response)

        stub_request(:patch, submission_update_url).to_return(status: 200)

        ValidateSubmissionJob.perform exercise_id, submission_id, token
      end

      it('should have downloaded the submission') { expect(WebMock).to have_requested(:get, submission_download_url).once }
      it('should have downloaded the test') { expect(WebMock).to have_requested(:get, exercise_test_download_url).once }
      it('should have downloaded the hidden_test') { expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once }

      it('should have made a patch request to update the validation status') { expect(WebMock).to have_requested(:patch, submission_update_url).once }
    end
  end

  describe 'validate_exercise' do
    context 'with problems' do
      describe "can't compile" do
        let(:result) { ValidateSubmissionJob.validate_submission test_jar_path, test_jar_path, test_jar_path }

        it('should have result grouped as submission') { expect(result).to include(:submission)}
        it('should have a failed status') { expect(result[:submission]).to include(validation_status: :failed)}
        it('should have general_validation_error') { expect(result[:submission]).to include(:general_validation_error_details)}
        it('should have empty_file_validation') { expect(result[:submission]).to include(file_validation_error: nil)}
        it("should have general_validation_error with a doesn't compile message") do
          expect(result[:submission]).to include(general_validation_error: I18n.t('validation.submission_doesnt_compile'))
        end
      end
    end
  end

  context 'without problems' do
    let(:result) { ValidateSubmissionJob.validate_submission test_jar_path, hidden_test_jar_path, submission_jar_path }

    it('should have result grouped as submission') { expect(result).to include(:submission)}
    it('should have a success status') { expect(result[:submission]).to include(validation_status: :success)}
    it('should have empty general_validation_error') { expect(result[:submission]).to include(general_validation_error_details: nil)}
    it('should have empty file_validation') { expect(result[:submission]).to include(file_validation_error: nil)}
    it('should have empty general_validation_error') { expect(result[:submission]).to include(general_validation_error: nil) }
  end
end
