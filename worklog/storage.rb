# frozen_string_literal: true
require_relative 'daily_log'


module Storage
  FILE_SUFFIX = '.yaml'
  DATA_DIR = File.join(Dir.home, '.worklog')

  def self.folder_exists?
    Dir.exist?(DATA_DIR)
  end

  # Return all days with logs
  def self.all_days
    return [] if !folder_exists?

    logs = []
    Dir.glob(File.join(DATA_DIR, "*#{FILE_SUFFIX}")).map do |file|
      logs << load_log(file)
    end

    logs
  end

  # Return days between start_date and end_date
  # If end_date is nil, return logs from start_date to today
  def self.days_between(start_date, end_date = nil, epics_only = nil, tags_filter = nil)
    return [] if !folder_exists?

    logs = []
    end_date = Date.today if end_date.nil?

    return [] if start_date > end_date

    while start_date <= end_date
      if File.exist?(filepath(start_date))
        tmp_logs = load_log(filepath(start_date))
        tmp_logs.entries.keep_if { |entry| entry.epic? } if epics_only

        if tags_filter
          # Safeguard against entries without any tags, not just empty array
          tmp_logs.entries.keep_if { |entry| entry.tags && (entry.tags & tags_filter).size > 0 }
        end


        if tmp_logs.entries.length > 0
          logs << tmp_logs
        end
      end

      start_date += 1
    end
    logs
  end

  # Create file for a new day if it does not exist
  def self.create_file_skeleton(date)
    create_folder

    unless File.exist?(filepath(date))
      File.write(filepath(date), YAML.dump(DailyLog.new(date, [])))
    end
  end

  def self.load_log(file)
    $logger.debug "Loading file #{file}"
    log = YAML.load_file(file, permitted_classes: [Date, Time, DailyLog, LogEntry])
    log.entries.each do |entry|
      unless entry.time.respond_to?(:strftime)
        entry.time = Time.parse(entry.time)
      end
    end
    log
  end

  def self.write_log(file, daily_log)
    create_folder

    $logger.debug "Writing to file #{file}"

    File.open(file, 'w') do |f|
      f.puts daily_log.to_yaml
    end
  end


  def self.load_single_log_file(file, headline = true)
    daily_log = load_log(file)
    if headline
      puts "Work log for #{Rainbow(daily_log.date).gold}:"
    end
    daily_log.entries
  end

  private

  # Create folder if not exists already.
  def create_folder
    unless Dir.exist?(DATA_DIR)
      Dir.mkdir(DATA_DIR)
    end
  end

  def filepath(date)
    # Construct filepath for a given date.
    File.join(DATA_DIR, "#{date}#{FILE_SUFFIX}")
  end

  module_function :create_folder, :filepath
end
