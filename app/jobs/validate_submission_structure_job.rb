class ValidateSubmissionStructureJob < ApplicationJob
  include Utils
  queue_as :default

  def perform(exercise_id, token)
    # Do something later
  end
end
