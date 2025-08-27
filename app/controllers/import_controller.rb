class ImportController < ApplicationController
  def create
    begin
      json_data = JSON.parse(request.body.read)

      job = RestaurantImportJob.perform_later(json_data)

      render json: {
        success: true,
        message: "Import job enqueued successfully",
        job_id: job.provider_job_id,
        status: "queued",
        check_status_command: "curl http://localhost:3000/import/status/#{job.provider_job_id}"
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

      json_content = uploaded_file.read
      json_data = JSON.parse(json_content)

      job = RestaurantImportJob.perform_later(json_data)

      render json: {
        success: true,
        message: "Import job enqueued successfully",
        job_id: job.provider_job_id,
        status: "queued",
        check_status_command: "curl http://localhost:3000/import/status/#{job.provider_job_id}"
      }, status: :accepted

    rescue JSON::ParserError => e
      render json: {
        success: false,
        error: "Invalid JSON format in uploaded file",
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

  def status
    job_id = params[:job_id]

    if job_id.blank?
      render json: {
        success: false,
        error: "Job ID is required"
      }, status: :bad_request
      return
    end

    # Try to find the job in Solid Queue
    job = SolidQueue::Job.find_by(id: job_id)

    if job.nil?
      render json: {
        success: false,
        error: "Job not found"
      }, status: :not_found
      return
    end

    # Check job status from Solid Queue
    case job.status
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
      # Job completed, try to get cached results
      cached_results = get_cached_results(job_id)
      if cached_results
        status_info = {
          state: "completed",
          message: "Job completed successfully",
          results: cached_results
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
        state: job.status,
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

  def get_cached_results(job_id)
    # Retrieve cached results using the job ID
    cache_key = "import_results:job:#{job_id}"
    Rails.cache.read(cache_key)
  end
end
