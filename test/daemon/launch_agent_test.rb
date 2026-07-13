# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require 'thor'
require_relative '../test_helper'
require 'daemon/launch_agent'

class LaunchAgentTest < Minitest::Test
  def setup
    @home = Dir.mktmpdir('worklog_home')
    ENV.delete('WORKLOG_DATABASE_URL')
  end

  def teardown
    FileUtils.rm_rf(@home)
    ENV.delete('WORKLOG_DATABASE_URL')
  end

  def test_install_writes_plist_with_absolute_paths
    Dir.stub :home, @home do
      Worklog::Daemon::LaunchAgent.stub :launchctl, true do
        Worklog::Daemon::LaunchAgent.install!
      end

      xml = File.read(Worklog::Daemon::LaunchAgent.plist_path)

      assert_includes xml, '<string>com.fewald.worklogd</string>'
      assert_includes xml, "<string>#{RbConfig.ruby}</string>"
      assert_includes xml, '<string>sync</string>'
      assert_includes xml, '<integer>3600</integer>'
      assert_includes xml, '<key>RunAtLoad</key>'
      assert_includes xml, File.join(@home, 'Library', 'Logs', 'worklogd.err')
    end
  end

  def test_install_honors_custom_interval
    Dir.stub :home, @home do
      Worklog::Daemon::LaunchAgent.stub :launchctl, true do
        Worklog::Daemon::LaunchAgent.install!(interval: 1800)
      end

      assert_includes File.read(Worklog::Daemon::LaunchAgent.plist_path), '<integer>1800</integer>'
    end
  end

  def test_yaml_engine_plist_has_no_database_url
    Dir.stub :home, @home do
      refute_includes Worklog::Daemon::LaunchAgent.plist_xml, 'WORKLOG_DATABASE_URL'
    end
  end

  def test_postgres_engine_plist_includes_database_url
    config = Worklog::Configuration.new do |c|
      c.storage = Worklog::Configuration::StorageConfig.new
      c.storage.engine = :postgres
      c.storage.postgres_url = 'postgres://localhost/worklog'
    end

    Dir.stub :home, @home do
      xml = Worklog::Daemon::LaunchAgent.plist_xml(config: config)

      assert_includes xml, '<key>WORKLOG_DATABASE_URL</key>'
      assert_includes xml, 'postgres://localhost/worklog'
    end
  end

  def test_uninstall_removes_plist
    Dir.stub :home, @home do
      Worklog::Daemon::LaunchAgent.stub :launchctl, true do
        Worklog::Daemon::LaunchAgent.install!

        assert_path_exists Worklog::Daemon::LaunchAgent.plist_path

        Worklog::Daemon::LaunchAgent.uninstall!

        refute_path_exists Worklog::Daemon::LaunchAgent.plist_path
      end
    end
  end

  def test_loaded_reflects_launchctl_exit_status
    Dir.stub :home, @home do
      Worklog::Daemon::LaunchAgent.stub :launchctl, true do
        assert_predicate Worklog::Daemon::LaunchAgent, :loaded?
      end
      Worklog::Daemon::LaunchAgent.stub :launchctl, false do
        refute_predicate Worklog::Daemon::LaunchAgent, :loaded?
      end
    end
  end

  def test_tail_log_returns_last_lines
    Dir.stub :home, @home do
      path = Worklog::Daemon::LaunchAgent.log_path
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "a\nb\nc\n")

      assert_equal %w[b c], Worklog::Daemon::LaunchAgent.tail_log(2)
    end
  end

  def test_tail_log_empty_when_no_log
    Dir.stub :home, @home do
      assert_empty Worklog::Daemon::LaunchAgent.tail_log
    end
  end

  def test_reload_raises_when_bootstrap_fails
    Dir.stub :home, @home do
      Worklog::Daemon::LaunchAgent.stub :launchctl, false do
        assert_raises(Thor::Error) { Worklog::Daemon::LaunchAgent.reload! }
      end
    end
  end
end
