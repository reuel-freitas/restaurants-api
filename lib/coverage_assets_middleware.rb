class CoverageAssetsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.path.start_with?("/coverage/assets/") || request.path.start_with?("/assets/")
      serve_coverage_asset(request.path)
    else
      @app.call(env)
    end
  end

  private

  def serve_coverage_asset(path)
    asset_path = if path.start_with?("/coverage/assets/")
                   path.sub("/coverage/", "")
    elsif path.start_with?("/assets/")
                   path.sub("/assets/", "coverage/assets/")
    else
                   path
    end

    full_path = Rails.root.join(asset_path)

    if File.exist?(full_path)
      content_type = determine_content_type(full_path)
      content = File.read(full_path)

      [
        200,
        {
          "Content-Type" => content_type,
          "Content-Length" => content.bytesize.to_s,
          "Cache-Control" => "public, max-age=3600"
        },
        [ content ]
      ]
    else
      [ 404, { "Content-Type" => "text/plain" }, [ "Asset not found: #{asset_path}" ] ]
    end
  end

  def determine_content_type(file_path)
    case File.extname(file_path)
    when ".css"
      "text/css"
    when ".js"
      "application/javascript"
    when ".png"
      "image/png"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".gif"
      "image/gif"
    when ".svg"
      "image/svg+xml"
    else
      "application/octet-stream"
    end
  end
end
