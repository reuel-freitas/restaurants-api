class HealthController < ApplicationController
  include HealthHelper

  def show
    health_check_result = HealthCheckService.perform_health_check

    restaurant_stats = RestaurantStatsService.generate_stats(
      with_items: false
    )

    # Para o health check, usar apenas o resumo dos restaurantes
    if restaurant_stats[:restaurants]
      restaurant_stats[:restaurants] = RestaurantStatsService.new.generate_restaurant_summary
    end

    @status = health_check_result[:status]
    @overall_status = health_check_result[:overall_status]
    @restaurant_stats = restaurant_stats

    # Content negotiation manual para ActionController::API
    case request.format.symbol
    when :json
      render json: @status.merge(restaurant_stats: @restaurant_stats)
    when :text
      render plain: generate_status_text(@status, @overall_status, @restaurant_stats)
    else
      render html: generate_health_html(@status, @overall_status, @restaurant_stats).html_safe
    end
  end

  def coverage
    coverage_path = Rails.root.join("coverage", "index.html")

    if File.exist?(coverage_path)
      # Se o arquivo de cobertura existe, serve o conteúdo diretamente
      content = File.read(coverage_path)
      render html: content.html_safe, content_type: "text/html"
    else
      # Se não existe, mostra uma mensagem informativa
      render html: generate_coverage_info_html.html_safe, content_type: "text/html"
    end
  end

  private

  def generate_status_text(status, overall_status, restaurant_stats)
    lines = []
    lines << "Restaurants API Health Check"
    lines << "============================"
    lines << "Status: #{overall_status.upcase}"
    lines << "Timestamp: #{status[:timestamp]}"
    lines << "Environment: #{status[:environment]}"
    lines << ""
    lines << "Database: #{status[:database][:status]} - #{status[:database][:message]}"
    lines << "Background Jobs: #{status[:background_jobs][:status]} - #{status[:background_jobs][:message]}"
    if status[:background_jobs][:total_jobs]
      lines << "  Total Jobs: #{status[:background_jobs][:total_jobs]}"
      lines << "  Failed Jobs: #{status[:background_jobs][:failed_jobs]}"
    end
    lines << "Ruby Version: #{status[:system_info][:ruby_version]}"
    lines << "Rails Version: #{status[:system_info][:rails_version]}"
    lines << "PostgreSQL: #{status[:system_info][:postgresql_version]}"
    lines << "Memory Usage: #{status[:system_info][:memory_usage]}"

    # Adicionar estatísticas dos restaurantes
    if restaurant_stats && !restaurant_stats[:error]
      lines << ""
      lines << "Restaurant Statistics"
      lines << "===================="
      stats = restaurant_stats
      lines << "Total Restaurants: #{stats[:summary][:total_restaurants]}"
      lines << "Total Menus: #{stats[:summary][:total_menus]}"
      lines << "Total Menu Items: #{stats[:summary][:total_menu_items]}"
      lines << "Total Menu Item Instances: #{stats[:summary][:total_menu_item_instances]}"
      lines << "Average Menus per Restaurant: #{stats[:summary][:average_menus_per_restaurant]}"
      lines << "Average Items per Menu: #{stats[:summary][:average_items_per_menu]}"

      if stats[:pricing_analysis][:price_ranges][:min] > 0
        lines << ""
        lines << "Pricing Analysis"
        lines << "================"
        lines << "Price Range: $#{stats[:pricing_analysis][:price_ranges][:min]} - $#{stats[:pricing_analysis][:price_ranges][:max]}"
        lines << "Average Price: $#{stats[:pricing_analysis][:price_ranges][:average]}"
      end

      # Adicionar informações de paginação
      if stats[:pagination]
        lines << ""
        lines << "Pagination"
        lines << "==========="
        lines << "Page: #{stats[:pagination][:current_page]} of #{stats[:pagination][:total_pages]}"
        lines << "Per Page: #{stats[:pagination][:per_page]}"
        lines << "Total: #{stats[:pagination][:total_count]} restaurants"
        if stats[:pagination][:next_page]
          lines << "Next Page: #{stats[:pagination][:next_page]}"
        end
        if stats[:pagination][:prev_page]
          lines << "Previous Page: #{stats[:pagination][:prev_page]}"
        end
      end
    else
      lines << ""
      lines << "Restaurant Statistics: #{restaurant_stats[:error] || 'Unavailable'}"
    end

    lines.join("\n")
  end
end
