# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require 'commands/daemon_command'
require 'worklog'

class DaemonCommandTest < Minitest::Test
  def setup
    @home = Dir.mktmpdir('worklog_home')
  end

  def teardown
    FileUtils.rm_rf(@home)
  end

  def test_run_invokes_github_sync_once
    calls = []

    Dir.stub :home, @home do
      WorkLogger.stub :log_to_file, nil do
        Worklog::Worklog.stub :new, fake_worklog(calls) do
          Worklog::Commands::DaemonCommand.new.invoke(:sync, [])
        end
      end
    end

    assert_equal [{}], calls
  end

  def test_run_swallows_errors_and_logs
    errors = []

    Dir.stub :home, @home do
      WorkLogger.stub :log_to_file, nil do
        WorkLogger.stub :error, ->(msg) { errors << msg } do
          Worklog::Worklog.stub :new, ->(*) { raise StandardError, 'boom' } do
            Worklog::Commands::DaemonCommand.new.invoke(:sync, [])
          end
        end
      end
    end

    assert_match(/worklogd sync failed/, errors.first)
  end

  def test_run_swallows_system_exit
    Dir.stub :home, @home do
      WorkLogger.stub :log_to_file, nil do
        WorkLogger.stub :error, nil do
          Worklog::Worklog.stub :new, ->(*) { raise SystemExit } do
            # Must not let SystemExit escape the command (launchd would see a crash).
            Worklog::Commands::DaemonCommand.new.invoke(:sync, [])
          end
        end
      end
    end

    assert_equal 0, $CHILD_STATUS.exitstatus if $CHILD_STATUS
    pass # SystemExit was swallowed; the command must not propagate it
  end

  def test_run_skips_when_lock_is_held
    calls = []

    Dir.stub :home, @home do
      lock = hold_lock
      begin
        WorkLogger.stub :log_to_file, nil do
          Worklog::Worklog.stub :new, fake_worklog(calls) do
            Worklog::Commands::DaemonCommand.new.invoke(:sync, [])
          end
        end
      ensure
        lock.flock(File::LOCK_UN)
        lock.close
      end
    end

    assert_empty calls
  end

  def test_install_warns_when_github_unconfigured
    out, = capture_io do
      Dir.stub :home, @home do
        Worklog::Daemon::LaunchAgent.stub :install!, nil do
          Worklog::Commands::DaemonCommand.new.invoke(:install, [], interval: 3600)
        end
      end
    end

    assert_match(/github\.api_key is not set/, out)
  end

  private

  # Returns a callable stub for Worklog::Worklog.new whose #github records calls.
  def fake_worklog(calls)
    fake = Object.new
    fake.define_singleton_method(:github) { |opts| calls << opts }
    ->(*) { fake }
  end

  # Open and exclusively flock the daemon lock file, simulating an in-flight sync.
  def hold_lock
    path = Worklog::Daemon::LaunchAgent.lock_path
    FileUtils.mkdir_p(File.dirname(path))
    handle = File.open(path, File::CREAT | File::RDWR)
    handle.flock(File::LOCK_EX | File::LOCK_NB)
    handle
  end
end
