# frozen_string_literal: true

require_relative 'test_helper'
require 'project_storage'
require 'date'

class ProjectStorageTest < Minitest::Test
  def setup
    @configuration = configuration_helper
    @project_storage = Worklog::ProjectStorage.new(@configuration)
  end

  def teardown
    temp_file = File.join(@configuration.storage_path, Worklog::ProjectStorage::FILE_NAME)
    File.delete(temp_file) if File.exist?(temp_file)
  end

  def test_load_projects
    # Create a temporary file to simulate the projects.yaml file
    temp_file = File.join(@configuration.storage_path, Worklog::ProjectStorage::FILE_NAME)
    yaml_content = <<~YAML
      - key: P001
        name: Test Project
        description: A test project
        start_date: 2023-01-01
        end_date: 2023-12-31
        status: active
      - key: P002
        name: Another Project
        description: Another test project
        start_date: 2023-02-01
        end_date: 2023-11-30
        status: completed
    YAML
    File.write(temp_file, yaml_content)
    projects = @project_storage.load_projects
    assert_instance_of Hash, projects
    assert_equal 2, projects.size
    assert_instance_of Worklog::Project, projects['P001']
    assert_equal 'Test Project', projects['P001'].name
    assert_equal 'A test project', projects['P001'].description
    assert_instance_of Date, projects['P001'].start_date
    assert_instance_of Date, projects['P001'].end_date
    assert_equal 'active', projects['P001'].status
    assert_instance_of Worklog::Project, projects['P002']
    assert_equal 'Another Project', projects['P002'].name
    assert_equal 'Another test project', projects['P002'].description
    assert_instance_of Date, projects['P002'].start_date
    assert_instance_of Date, projects['P002'].end_date
    assert_equal 'completed', projects['P002'].status
  end

  def test_projects
    project_storage = Worklog::ProjectStorage.new(@configuration)
    assert_instance_of Worklog::ProjectStorage, project_storage

    project_storage.projects = {
      'P001' => Worklog::Project.from_hash(
        key: 'P001',
        name: 'Test Project',
        description: 'A test project',
        start_date: Date.new(2023, 1, 1),
        end_date: Date.new(2023, 12, 31),
        status: 'active'
      ),
      'P002' => Worklog::Project.from_hash(
        key: 'P002',
        name: 'Another Project',
        description: 'Another test project',
        start_date: Date.new(2023, 2, 1),
        end_date: Date.new(2023, 11, 30),
        status: 'completed'
      )
    }

    assert_equal 2, project_storage.projects.size
  end

  def test_load_folder_does_not_exist
    project_storage = Worklog::ProjectStorage.new(@configuration)
    assert_instance_of Worklog::ProjectStorage, project_storage

    # Temporarily change the storage path to a non-existent folder
    original_path = @configuration.storage_path
    @configuration.storage_path = '/non/existent/path'

    assert_raises(Errno::ENOENT) do
      project_storage.load_projects
    end

  ensure
    # Restore the original storage path
    @configuration.storage_path = original_path
  end
end
