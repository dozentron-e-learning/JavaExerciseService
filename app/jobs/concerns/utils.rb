require 'zip'
require 'open3'

module Utils
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    EXECUTION_DIRECTORY_TEMPLATE = 'gradle_execution_environment_template'.freeze
    EXECUTION_DIRECTORY = 'gradle_execution_environment'.freeze

    def download_exercise(token, id, file_name)
      tempfile = Down.download("#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download")
      FileUtils.mv tempfile.path, execution_directory(file_name)
    end

    def download_exercise_hidden(token, id, file_name)
      tempfile = Down.download("#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download_hidden")
      FileUtils.mv tempfile.path, execution_directory(file_name)
    end

    def download_exercise_stub(token, id, file_name)
      tempfile = Down.download("#{Rails.configuration.service_urls.exercise_service}/api/v1/exercise/#{id}/download_stub")
      FileUtils.mv tempfile.path, execution_directory(file_name)
    end

    def download_submission(token, id, file_name)
      tempfile = Down.download("#{Rails.configuration.service_urls.submission_service}/api/v1/submission/#{id}/download")
      FileUtils.mv tempfile.path, execution_directory(file_name)
    end

    def run_gradle_task(*args)
      ::Open3.popen3('./gradlew', *args, chdir: execution_directory)
    end

    def execution_directory(*path_elements)
      Rails.root.join EXECUTION_DIRECTORY, *path_elements
    end

    ##
    # Prepares an execution directory by copying the +EXECUTION_DIRECTORY_TEMPLATE+ directory to +execution_directory+
    def prepare_execution_environment
      FileUtils.rm_rf execution_directory
      FileUtils.copy_entry Rails.root.join(EXECUTION_DIRECTORY_TEMPLATE), execution_directory
    end

    def can_be_opened_as_zip?(path)
      begin
        Zip::File.open(path) {}
      rescue
        return false
      end

      true
    end

    def contains_java_files?(path)
      Dir["#{path}/**/*.java"].any?
    end

    def contains_class_files?(path)
      Dir["#{path}/**/*.class"].any?
    end

    def validate_jar(path, dir_path)
      return I18n.t :'validation.not_a_jar' unless can_be_opened_as_zip? path

      unzip_file path, dir_path
      return I18n.t :'validation.needs_source_files' unless contains_java_files? dir_path
      return I18n.t :'validation.needs_class_files' unless contains_class_files? dir_path
    end

    def unzip_file(file, destination = execution_directory)
      ::Zip::File.open(file) { |zip_file|
        zip_file.each { |f|
          f_path = File.join(destination, f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        }
      }
    end
  end
end