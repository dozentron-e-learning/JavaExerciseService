class ValidateExerciseStructureJob
  include Utils

  def perform(exercise_id, token)
    download_exercise exercise_id, token, "jar"
    puts "hallo welt"
  end
end
