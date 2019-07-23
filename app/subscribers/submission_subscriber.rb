class SubmissionSubscriber < ActiveBunny::Subscriber
  def create(submission)
    Resque.enqueue ValidateSubmissionJob, submission.exercise_id, submission.id, submission.auth_token
  end

  def update(submission)
    Resque.enqueue ExecuteExerciseJob, submission.exercise_id, submission.id, submission.auth_token
  end
end