class ExerciseSubscriber < ActiveBunny::Subscriber
  def create(exercise_json)
    exercise = JSON.parse(exercise_json).with_indifferent_access
    Rails.logger.info "Accepted new Exercise Validation Job for exercise: #{exercise[:id]}"
    Resque.enqueue ValidateExerciseJob, exercise[:id], exercise[:validation_token]
  end
end