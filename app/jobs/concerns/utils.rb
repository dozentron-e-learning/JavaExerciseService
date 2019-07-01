
module Utils
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def download_exercise(token, id, suffix="jar")
      `wget "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download" -O "test.#{suffix}"`
      `wget "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download_hidden" -O "hidden_test.#{suffix}"`
    end

    def download_exercise_stub(token, id, suffix="jar")
      `wget "#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download_stub" -O "stub.#{suffix}"`
    end

    def download_submission(token, id, suffix="jar")
      `wget "#{Rails.configuration.service_urls.submission_service}/api/v1/submission/#{id}/download" -O "submission.#{suffix}"`
    end
  end
end