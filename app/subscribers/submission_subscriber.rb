class SubmissionSubscriber < ActiveBunny::Subscriber
  def create(submission_json)
    submission = JSON.parse(submission_json).with_indifferent_access
    return unless submission[:plugin] == Rails.application.config.plugin_name

    Rails.logger.info "Accepted new Submission Validation Job for submission: #{submission[:id]} and exercise: #{submission[:exercise_id]}"
    Resque.enqueue ValidateSubmissionJob, submission[:exercise_id], submission[:id], submission[:validation_token]
  end

  def update(submission_json)
    submission = JSON.parse(submission_json).with_indifferent_access
    return unless submission[:plugin] == Rails.application.config.plugin_name

    Rails.logger.info "Accepted new Execution Job for submission: #{submission[:id]} and exercise: #{submission[:exercise_id]}"
    Resque.enqueue ExecuteExerciseJob, submission[:exercise_id], submission[:id], submission[:validation_token]
  end
end