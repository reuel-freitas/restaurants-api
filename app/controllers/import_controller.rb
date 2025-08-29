class ImportController < ApplicationController
  def create
    begin
      json_data = JSON.parse(request.body.read)

      unless json_data.is_a?(Hash)
        render json: {
          success: false,
          error: "Invalid data structure",
          details: "Data must be a JSON object"
        }, status: :bad_request
        return
      end

      job = RestaurantImportJob.perform_later(json_data)
      job_id = job.job_id

      render json: {
        success: true,
        message: "Import job enqueued successfully",
        job_id: job_id,
        status: "queued",
        check_status_command: "curl http://localhost:3000/import/status/#{job_id}",
        note: "Consider using file upload for better performance with large datasets"
      }, status: :accepted

    rescue JSON::ParserError => e
      render json: {
        success: false,
        error: "Invalid JSON format",
        details: e.message
      }, status: :bad_request

    rescue StandardError => e
      render json: {
        success: false,
        error: "Failed to enqueue import job",
        details: e.message
      }, status: :internal_server_error
    end
  end

  def upload
    begin
      uploaded_file = params[:file]

      if uploaded_file.nil?
        render json: {
          success: false,
          error: "No file provided"
        }, status: :bad_request
        return
      end

      if uploaded_file.size > RestaurantImportService::MAX_FILE_SIZE
        render json: {
          success: false,
          error: "File too large",
          details: "Maximum file size is #{RestaurantImportService::MAX_FILE_SIZE / (1024 * 1024)}MB"
        }, status: :bad_request
        return
      end


      begin
        json_content = uploaded_file.read
        JSON.parse(json_content)
        uploaded_file.rewind
      rescue JSON::ParserError => e
        render json: {
          success: false,
          error: "Invalid JSON format in uploaded file",
          details: e.message
        }, status: :bad_request
        return
      end

      temp_file_path = save_uploaded_file(uploaded_file)

      job = RestaurantImportJob.perform_later(temp_file_path)
      job_id = job.job_id

      render json: {
        success: true,
        message: "Import job enqueued successfully",
        job_id: job_id,
        status: "queued",
        check_status_command: "curl http://localhost:3000/import/status/#{job_id}",
        file_size: format_file_size(uploaded_file.size),
        note: "File-based import provides better performance for large datasets"
      }, status: :accepted

    rescue StandardError => e
      render json: {
        success: false,
        error: "Failed to enqueue import job",
        details: e.message
      }, status: :internal_server_error
    end
  end

  def status
    job_id = params[:job_id]

    if job_id.blank?
      render json: {
        success: false,
        error: "Job ID is required"
      }, status: :bad_request
      return
    end

    job = SolidQueue::Job.find_by(active_job_id: job_id) || SolidQueue::Job.find_by(id: job_id)

    if job.nil?
      render json: {
        success: false,
        error: "Job not found"
      }, status: :not_found
      return
    end

    # Debug: log the actual status
    Rails.logger.debug "Job status: '#{job.status}' (class: #{job.status.class})"

    case job.status.to_s
    when "pending"
      status_info = {
        state: "queued",
        message: "Job is waiting to be processed"
      }
    when "claimed"
      status_info = {
        state: "processing",
        message: "Job is currently being processed"
      }
    when "finished"
      cached_results = get_cached_results(job_id)
      if cached_results
        status_info = {
          state: "completed",
          message: "Job completed successfully",
          results: cached_results,
          item_logs: cached_results[:item_logs] || []
        }
      else
        status_info = {
          state: "completed",
          message: "Job completed but results not available"
        }
      end
    when "failed"
      status_info = {
        state: "failed",
        message: "Job failed during execution"
      }
    else
      status_info = {
        state: job.status.to_s,
        message: "Job is in #{job.status} state"
      }
    end

    render json: {
      success: true,
      job_id: job_id,
      status: status_info
    }, status: :ok
  end

  private

  def save_uploaded_file(uploaded_file)
    temp_dir = Rails.root.join("tmp", "imports")
    FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir)

    filename = "import_#{SecureRandom.uuid}_#{uploaded_file.original_filename}"
    temp_file_path = temp_dir.join(filename)

    File.open(temp_file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end

    temp_file_path.to_s
  end

  def get_cached_results(job_id)
    cache_key = "import_results:job:#{job_id}"
    Rails.cache.read(cache_key)
  end

  def format_file_size(bytes)
    if bytes >= 1024 * 1024
      "#{(bytes / (1024.0 * 1024.0)).round(2)}MB"
    elsif bytes >= 1024
      "#{(bytes / 1024.0).round(2)}KB"
    else
      "#{bytes}B"
    end
  end
end
