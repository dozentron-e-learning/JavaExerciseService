class ExerciseSubscriber < ActiveBunny::Subscriber
  PLUGIN_NAME = 'java12_junit_5'
  def create(exercise_json)
    exercise = JSON.parse(exercise_json).with_indifferent_access
    return unless exercise[:plugin] == Rails.application.config.plugin_name

    Rails.logger.info "Accepted new Exercise Validation Job for exercise: #{exercise[:id]}"
    Resque.enqueue ValidateExerciseJob, exercise[:id], exercise[:validation_token]
  end
end