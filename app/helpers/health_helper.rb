module HealthHelper
  def generate_health_html(status, overall_status, restaurant_stats)
    # Generate the complete HTML response inline
    html = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Restaurants API - Health Check</title>
          <style>
              * {
                  margin: 0;
                  padding: 0;
                  box-sizing: border-box;
              }

              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  min-height: 100vh;
                  padding: 20px;
              }

              .container {
                  max-width: 1200px;
                  margin: 0 auto;
                  background: white;
                  border-radius: 16px;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                  overflow: hidden;
              }

              .header {
                  background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
                  color: white;
                  padding: 40px;
                  text-align: center;
              }

              .header h1 {
                  font-size: 2.5rem;
                  margin-bottom: 10px;
                  font-weight: 300;
              }

              .header .subtitle {
                  font-size: 1.2rem;
                  opacity: 0.9;
                  font-weight: 300;
              }

              .status-banner {
                  padding: 20px 40px;
                  text-align: center;
                  font-size: 1.1rem;
                  font-weight: 500;
              }

              .status-healthy {
                  background: linear-gradient(135deg, #27ae60 0%, #2ecc71 100%);
                  color: white;
              }

              .status-degraded {
                  background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                  color: white;
              }

              .status-unhealthy {
                  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                  color: white;
              }

              .content {
                  padding: 40px;
              }

              .status-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                  gap: 24px;
                  margin-bottom: 40px;
              }

              .status-card {
                  background: #f8f9fa;
                  border-radius: 12px;
                  padding: 24px;
                  border-left: 4px solid #dee2e6;
              }

              .status-card.healthy {
                  border-left-color: #27ae60;
                  background: linear-gradient(135deg, #f8f9fa 0%, #e8f5e8 100%);
              }

              .status-card.unhealthy {
                  border-left-color: #e74c3c;
                  background: linear-gradient(135deg, #f8f9fa 0%, #ffeaea 100%);
              }

              .status-card.unavailable {
                  border-left-color: #95a5a6;
                  background: linear-gradient(135deg, #f8f9fa 0%, #f0f0f0 100%);
              }

              .card-header {
                  display: flex;
                  align-items: center;
                  margin-bottom: 16px;
              }

              .status-indicator {
                  width: 12px;
                  height: 12px;
                  border-radius: 50%;
                  margin-right: 12px;
              }

              .status-indicator.healthy { background: #27ae60; }
              .status-indicator.unhealthy { background: #e74c3c; }
              .status-indicator.unavailable { background: #95a5a6; }

              .card-title {
                  font-size: 1.1rem;
                  font-weight: 600;
                  color: #2c3e50;
              }

              .card-content {
                  color: #5a6c7d;
                  line-height: 1.6;
              }

              .system-info {
                  background: #f8f9fa;
                  border-radius: 12px;
                  padding: 24px;
                  margin-bottom: 24px;
              }

              .system-info h3 {
                  color: #2c3e50;
                  margin-bottom: 16px;
                  font-size: 1.2rem;
              }

              .info-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                  gap: 16px;
              }

              .info-item {
                  display: flex;
                  justify-content: space-between;
                  padding: 8px 0;
                  border-bottom: 1px solid #e9ecef;
              }

              .info-label {
                  font-weight: 500;
                  color: #5a6c7d;
              }

              .info-value {
                  color: #2c3e50;
                  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
              }

              .restaurant-stats {
                  background: linear-gradient(135deg, #f8f9fa 0%, #e3f2fd 100%);
                  border-radius: 12px;
                  padding: 24px;
                  margin-bottom: 24px;
                  border-left: 4px solid #2196f3;
              }

              .restaurant-stats h3 {
                  color: #2c3e50;
                  margin-bottom: 16px;
                  font-size: 1.2rem;
                  display: flex;
                  align-items: center;
              }

              .restaurant-stats h3::before {
                  content: "🍽️";
                  margin-right: 8px;
              }

              .stats-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                  gap: 16px;
                  margin-bottom: 20px;
              }

              .stat-item {
                  background: white;
                  padding: 16px;
                  border-radius: 8px;
                  text-align: center;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }

              .stat-number {
                  font-size: 1.5rem;
                  font-weight: 700;
                  color: #2196f3;
                  display: block;
              }

              .stat-label {
                  font-size: 0.9rem;
                  color: #5a6c7d;
                  margin-top: 4px;
              }

              .pricing-analysis {
                  background: white;
                  padding: 20px;
                  border-radius: 8px;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
              }

              .pricing-analysis h4 {
                  color: #2c3e50;
                  margin-bottom: 12px;
                  font-size: 1rem;
              }

              .pricing-grid {
                  display: grid;
                  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
                  gap: 12px;
              }

              .footer {
                  background: #f8f9fa;
                  padding: 24px 40px;
                  text-align: center;
                  color: #6c757d;
                  border-top: 1px solid #e9ecef;
              }

              .footer a {
                  color: #667eea;
                  text-decoration: none;
              }

              .footer a:hover {
                  text-decoration: underline;
              }

              .timestamp {
                  font-size: 0.9rem;
                  opacity: 0.8;
              }

              @media (max-width: 768px) {
                  .header {
                      padding: 30px 20px;
                  }

                  .header h1 {
                      font-size: 2rem;
                  }

                  .content {
                      padding: 20px;
                  }

                  .status-grid {
                      grid-template-columns: 1fr;
                  }

                  .info-grid {
                      grid-template-columns: 1fr;
                  }

                  .stats-grid {
                      grid-template-columns: repeat(2, 1fr);
                  }
              }

              .pulse {
                  animation: pulse 2s infinite;
              }

              @keyframes pulse {
                  0% { opacity: 1; }
                  50% { opacity: 0.5; }
                  100% { opacity: 1; }
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <h1>🍽️ Restaurants API</h1>
                  <div class="subtitle">Health Check & System Status</div>
              </div>

              <div class="status-banner status-#{overall_status}">
                  <strong>System Status: #{overall_status.upcase}</strong>
                  #{overall_status == 'healthy' ? '✅ All systems operational' : overall_status == 'degraded' ? '⚠️ System experiencing issues' : '❌ System unhealthy'}
              </div>

              <div class="content">
                  <div class="status-grid">
                      <div class="status-card #{status[:database][:status]}">
                          <div class="card-header">
                              <div class="status-indicator #{status[:database][:status]}"></div>
                              <div class="card-title">Database</div>
                          </div>
                          <div class="card-content">
                              <strong>Status:</strong> #{status[:database][:status].capitalize}<br>
                              <strong>Message:</strong> #{status[:database][:message]}
                          </div>
                      </div>

                      <div class="status-card #{status[:background_jobs][:status]}">
                          <div class="card-header">
                              <div class="status-indicator #{status[:background_jobs][:status]}"></div>
                              <div class="card-title">Background Jobs</div>
                          </div>
                          <div class="card-content">
                              <strong>Status:</strong> #{status[:background_jobs][:status].capitalize}<br>
                              <strong>Message:</strong> #{status[:background_jobs][:message]}
                              #{status[:background_jobs][:total_jobs] ? "<br><strong>Total Jobs:</strong> #{status[:background_jobs][:total_jobs]}" : ""}
                              #{status[:background_jobs][:failed_jobs] ? "<br><strong>Failed Jobs:</strong> #{status[:background_jobs][:failed_jobs]}" : ""}
                          </div>
                      </div>
                  </div>

                  #{generate_restaurant_stats_html(restaurant_stats)}

                  <div class="system-info">
                      <h3>System Information</h3>
                      <div class="info-grid">
                          <div class="info-item">
                              <span class="info-label">Application:</span>
                              <span class="info-value">#{status[:application]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Version:</span>
                              <span class="info-value">#{status[:version]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Environment:</span>
                              <span class="info-value">#{status[:environment].capitalize}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Ruby Version:</span>
                              <span class="info-value">#{status[:system_info][:ruby_version]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Rails Version:</span>
                              <span class="info-value">#{status[:system_info][:rails_version]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">PostgreSQL:</span>
                              <span class="info-value">#{status[:system_info][:postgresql_version]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Memory Usage:</span>
                              <span class="info-value">#{status[:system_info][:memory_usage]}</span>
                          </div>
                          <div class="info-item">
                              <span class="info-label">Uptime:</span>
                              <span class="info-value">#{status[:uptime]}</span>
                          </div>
                      </div>
                  </div>
              </div>

              <div class="footer">
                  <div class="timestamp">
                      Last updated: #{status[:timestamp].strftime("%B %d, %Y at %I:%M:%S %p %Z")}
                  </div>
                  <div style="margin-top: 8px;">
                      <a href="/jobs">🔧 Mission Control Jobs</a> |#{' '}
                      <a href="/api-docs">📚 API Documentation</a> |#{' '}
                      <a href="/coverage" target="_blank">📊 Test Coverage</a>
                  </div>
              </div>
          </div>

          <script>
              // Auto-refresh every 30 seconds
              setTimeout(function() {
                  location.reload();
              }, 30000);

              // Add pulse animation to status indicators
              document.addEventListener('DOMContentLoaded', function() {
                  const indicators = document.querySelectorAll('.status-indicator');
                  indicators.forEach(function(indicator) {
                      if (indicator.classList.contains('unhealthy')) {
                          indicator.classList.add('pulse');
                      }
                  });
              });
          </script>
      </body>
      </html>
    HTML

    html
  end

  private

  def generate_coverage_info_html
    html = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Test Coverage - Restaurants API</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  min-height: 100vh;
                  margin: 0;
                  padding: 20px;
                  display: flex;
                  align-items: center;
                  justify-content: center;
              }
              .container {
                  background: white;
                  border-radius: 16px;
                  padding: 40px;
                  text-align: center;
                  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                  max-width: 600px;
              }
              h1 { color: #2c3e50; margin-bottom: 20px; }
              .message { color: #5a6c7d; line-height: 1.6; margin-bottom: 30px; }
              .command {
                  background: #f8f9fa;
                  border: 1px solid #e9ecef;
                  border-radius: 8px;
                  padding: 16px;
                  font-family: 'Monaco', 'Menlo', monospace;
                  color: #2c3e50;
                  margin: 20px 0;
              }
              .back-link {
                  display: inline-block;
                  background: #667eea;
                  color: white;
                  padding: 12px 24px;
                  text-decoration: none;
                  border-radius: 8px;
                  margin-top: 20px;
              }
              .back-link:hover { background: #5a6fd8; }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>📊 Test Coverage</h1>
              <div class="message">
                  O relatório de cobertura de testes ainda não foi gerado.
                  Para gerar o relatório, execute o comando:
              </div>
              <div class="command">
                  bundle exec rspec
              </div>
              <div class="message">
                  Após executar os testes, o relatório será gerado na pasta <code>coverage/</code>#{' '}
                  e você poderá visualizá-lo aqui.
              </div>
              <a href="/" class="back-link">← Voltar ao Health Check</a>
          </div>
      </body>
      </html>
    HTML

    html
  end

  def generate_restaurant_stats_html(restaurant_stats)
    return "" unless restaurant_stats && !restaurant_stats[:error]

    stats = restaurant_stats
    html = <<~HTML
      <div class="restaurant-stats">
          <h3>Restaurant Statistics</h3>
          <div class="stats-grid">
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:total_restaurants]}</span>
                  <div class="stat-label">Restaurants</div>
              </div>
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:total_menus]}</span>
                  <div class="stat-label">Menus</div>
              </div>
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:total_menu_items]}</span>
                  <div class="stat-label">Menu Items</div>
              </div>
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:total_menu_item_instances]}</span>
                  <div class="stat-label">Total Instances</div>
              </div>
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:average_menus_per_restaurant]}</span>
                  <div class="stat-label">Avg Menus/Restaurant</div>
              </div>
              <div class="stat-item">
                  <span class="stat-number">#{stats[:summary][:average_items_per_menu]}</span>
                  <div class="stat-label">Avg Items/Menu</div>
              </div>
          </div>
    HTML

    if stats[:pricing_analysis] && stats[:pricing_analysis][:price_ranges] && stats[:pricing_analysis][:price_ranges][:min] > 0
      html += <<~HTML
          <div class="pricing-analysis">
              <h4>💰 Pricing Analysis</h4>
              <div class="pricing-grid">
                  <div class="stat-item">
                      <span class="stat-number">$#{stats[:pricing_analysis][:price_ranges][:min]}</span>
                      <div class="stat-label">Min Price</div>
                  </div>
                  <div class="stat-item">
                      <span class="stat-number">$#{stats[:pricing_analysis][:price_ranges][:max]}</span>
                      <div class="stat-label">Max Price</div>
                  </div>
                  <div class="stat-item">
                      <span class="stat-number">$#{stats[:pricing_analysis][:price_ranges][:average]}</span>
                      <div class="stat-label">Average Price</div>
                  </div>
              </div>
          </div>
      HTML
    end

    # Adicionar informações de resumo dos restaurantes
    if stats[:restaurants] && stats[:restaurants][:sample_restaurants]
      html += <<~HTML
          <div class="pricing-analysis">
              <h4>📄 Restaurant Summary</h4>
              <div class="pricing-grid">
                  <div class="stat-item">
                      <span class="stat-number">#{stats[:restaurants][:total_count]}</span>
                      <div class="stat-label">Total Restaurants</div>
                  </div>
                  <div class="stat-item">
                      <span class="stat-number">#{stats[:restaurants][:sample_restaurants].length}</span>
                      <div class="stat-label">Sample Shown</div>
                  </div>
              </div>
              <div style="text-align: center; margin-top: 16px; color: #666; font-size: 14px;">
                  #{stats[:restaurants][:message]}
              </div>
          </div>
      HTML
    end

    html += "</div>"
    html
  end
end
