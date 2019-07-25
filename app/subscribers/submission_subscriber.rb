class SubmissionSubscriber < ActiveBunny::Subscriber
  def create(submission_json)
    submission = JSON.parse(submission_json).with_indifferent_access
    Resque.enqueue ValidateSubmissionJob, submission[:exercise_id], submission[:id], submission[:validation_token]
  end

  def update(submission_json)
    submission = JSON.parse(submission_json).with_indifferent_access
    Resque.enqueue ExecuteExerciseJob, submission[:exercise_id], submission[:id], submission[:validation_token]
  end
end