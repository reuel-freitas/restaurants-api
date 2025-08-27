class ImportController < ApplicationController
  def create
    begin
      json_data = JSON.parse(request.body.read)

      import_service = RestaurantImportService.new(json_data)
      result = import_service.import

      if result[:success]
        render json: result, status: :ok
      else
        render json: result, status: :unprocessable_entity
      end

    rescue JSON::ParserError => e
      render json: {
        success: false,
        error: "Invalid JSON format",
        details: e.message
      }, status: :bad_request

    rescue StandardError => e
      render json: {
        success: false,
        error: "Import failed",
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

      import_service = RestaurantImportService.new(json_data)
      result = import_service.import

      if result[:success]
        render json: result, status: :ok
      else
        render json: result, status: :unprocessable_entity
      end

    rescue JSON::ParserError => e
      render json: {
        success: false,
        error: "Invalid JSON format in uploaded file",
        details: e.message
      }, status: :bad_request

    rescue StandardError => e
      render json: {
        success: false,
        error: "Import failed",
        details: e.message
      }, status: :internal_server_error
    end
  end
end
