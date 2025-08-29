class HealthCheckService
  def self.perform_health_check
    new.perform_health_check
  end

  def perform_health_check
    @status = {
      application: "Restaurants API",
      version: "1.0.0",
      environment: Rails.env,
      timestamp: Time.current,
      uptime: calculate_uptime,
      database: check_database_status,
      background_jobs: check_background_jobs_status,
      system_info: get_system_info
    }

    @overall_status = determine_overall_status

    {
      status: @status,
      overall_status: @overall_status
    }
  end

  private

  def calculate_uptime
    if defined?(Rails::Server)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      uptime_seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      "#{uptime_seconds.to_i} seconds"
    else
      "Development mode"
    end
  rescue
    "Unknown"
  end

  def check_database_status
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      { status: "healthy", message: "Connected successfully" }
    rescue => e
      { status: "unhealthy", message: e.message }
    end
  end

  def check_background_jobs_status
    begin
      if defined?(SolidQueue)
        total_jobs = SolidQueue::Job.count

        failed_jobs = SolidQueue::FailedExecution.count
        if failed_jobs > 0
          status = "degraded"
          message = "Solid Queue operational with #{failed_jobs} failed jobs"
        else
          status = "healthy"
          message = "Solid Queue operational"
        end

        {
          status: status,
          message: message,
          total_jobs: total_jobs,
          failed_jobs: failed_jobs
        }
      else
        { status: "unavailable", message: "Solid Queue not configured" }
      end
    rescue => e
      { status: "unhealthy", message: e.message }
    end
  end

  def get_system_info
    {
      ruby_version: RUBY_VERSION,
      rails_version: Rails.version,
      postgresql_version: get_postgresql_version,
      memory_usage: get_memory_usage
    }
  end

  def get_postgresql_version
    begin
      version = ActiveRecord::Base.connection.execute("SELECT version()").first["version"]
      version.match(/PostgreSQL (\d+\.\d+)/)&.[](1) || "Unknown"
    rescue
      "Unknown"
    end
  end

  def get_memory_usage
    begin
      memory_kb = `ps -o rss= -p #{Process.pid}`.to_i
      "#{(memory_kb / 1024.0).round(2)} MB"
    rescue
      "Unknown"
    end
  end

  def determine_overall_status
    if @status[:database][:status] == "healthy" && @status[:background_jobs][:status] == "healthy"
      "healthy"
    elsif @status[:database][:status] == "healthy" && @status[:background_jobs][:status] == "degraded"
      "degraded"
    elsif @status[:database][:status] == "healthy"
      "degraded"
    else
      "unhealthy"
    end
  end
end
