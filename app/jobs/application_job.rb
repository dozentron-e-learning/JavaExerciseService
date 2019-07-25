require_relative 'concerns/utils'

class ApplicationJob
  include Utils

  SUBMISSION_FILENAME = 'submission.jar'.freeze
  TEST_FILENAME = 'test.jar'.freeze
  HIDDEN_TEST_FILENAME = 'hidden_test.jar'.freeze

  def self.on_failure(e, *args)
    LOGGER.error e
  end
end