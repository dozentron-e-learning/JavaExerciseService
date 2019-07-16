require 'rails_helper'

RSpec.describe ValidateExerciseJob, type: :job do
  before(:each) do
    # Clear Execution Environment before each test
    TestHelper.prepare_execution_environment
  end

  let(:exercise_id) { 1 }
  let(:token) { '' }

  let(:exercise_test_download_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{exercise_id}/download" }
  let(:exercise_hidden_test_download_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{exercise_id}/download_hidden" }
  let(:exercise_stub_download_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{exercise_id}/download_stub" }
  let(:exercise_update_url) { "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{exercise_id}" }

  let(:test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'test.jar') }
  let(:hidden_test_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'hidden_test.jar') }
  let(:stub_jar_path) { Rails.root.join('spec', 'resources', 'jars', 'stub.jar') }

  let(:test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'test_download')) }
  let(:hidden_test_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'hidden_test_download')) }
  let(:stub_response) { File.new(Rails.root.join('spec', 'resources', 'raw_curl_responses', 'stub_download')) }

  describe 'perform' do
    context 'valid test and submission' do
      before do
        stub_request(:get, exercise_test_download_url).to_return(test_response)
        stub_request(:get, exercise_hidden_test_download_url).to_return(hidden_test_response)
        stub_request(:get, exercise_stub_download_url).to_return(stub_response)

        stub_request(:patch, exercise_update_url).to_return(status: 200)

        ValidateExerciseJob.perform exercise_id, token
      end

      it('should have downloaded the submission') { expect(WebMock).to have_requested(:get, exercise_stub_download_url).once }
      it('should have downloaded the test') { expect(WebMock).to have_requested(:get, exercise_test_download_url).once }
      it('should have downloaded the hidden_test') { expect(WebMock).to have_requested(:get, exercise_hidden_test_download_url).once }

      it('should have made a patch request to update the validation status') { expect(WebMock).to have_requested(:patch, exercise_update_url).once }
    end
  end

  describe 'validate_exercise' do
    context 'with problems' do
      describe "can't compile" do
        let(:result) { ValidateExerciseJob.validate_exercise test_jar_path, test_jar_path, test_jar_path }

        it('should have result grouped as submission') { expect(result).to include(:api_v1_exercise)}
        it('should have empty tests')                  { expect(result[:api_v1_exercise]).to include(tests: {})}
        it('should have a failed status')              { expect(result[:api_v1_exercise]).to include(validation_status: :failed)}
        it('should have general_validation_error')     { expect(result[:api_v1_exercise]).to include(:general_validation_error_details)}
        it('should have empty test validation')        { expect(result[:api_v1_exercise]).to include(test_validation_error: nil)}
        it('should have empty hidden test validation') { expect(result[:api_v1_exercise]).to include(hidden_test_validation_error: nil)}
        it('should have empty stub validation')        { expect(result[:api_v1_exercise]).to include(stub_validation_error: nil)}
        it("should have general_validation_error with a doesn't compile message") do
          expect(result[:api_v1_exercise]).to include(general_validation_error: I18n.t('validation.test_doesnt_compile'))
        end
      end
    end
  end

  context 'without problems' do
    let(:result) { ValidateExerciseJob.validate_exercise test_jar_path, hidden_test_jar_path, stub_jar_path }

    it('should have result grouped as submission')   { expect(result).to include(:api_v1_exercise)}
    it('should have tests')                          { expect(result[:api_v1_exercise]).to include(tests: {"com.example.project.CalculatorTests" => ["addsTwoNumbers()"]})}
    it('should have a success status')               { expect(result[:api_v1_exercise]).to include(validation_status: :success)}
    it('should have empty general_validation_error') { expect(result[:api_v1_exercise]).to include(general_validation_error_details: nil)}
    it('should have empty test validation')          { expect(result[:api_v1_exercise]).to include(test_validation_error: nil)}
    it('should have empty hidden test validation')   { expect(result[:api_v1_exercise]).to include(hidden_test_validation_error: nil)}
    it('should have empty stub validation')          { expect(result[:api_v1_exercise]).to include(stub_validation_error: nil)}
    it('should have empty general_validation_error') { expect(result[:api_v1_exercise]).to include(general_validation_error: nil) }
  end
end
