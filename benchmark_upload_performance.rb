#!/usr/bin/env ruby

require_relative 'config/environment'
require 'benchmark'
require 'json'

class UploadPerformanceBenchmark
  def initialize
    @results = []
    @sizes = [
      { name: "Small", target_size: 100 * 1024 },
      { name: "Medium", target_size: 1 * 1024 * 1024 },
      { name: "Large", target_size: 3 * 1024 * 1024 },
      { name: "Limit", target_size: 4.5 * 1024 * 1024 }
    ]
  end

  def run_benchmark
    puts "🚀 Starting Upload Performance Benchmark"
    puts "=" * 60

    @sizes.each do |size_config|
      puts "\n📊 Testing: #{size_config[:name]} (#{format_size(size_config[:target_size])})"
      puts "-" * 40

      json_data = generate_test_data(size_config[:target_size])
      actual_size = json_data.to_json.bytesize

      puts "📏 Actual size: #{format_size(actual_size)}"

      result = benchmark_import(json_data)

      @results << {
        size_name: size_config[:name],
        target_size: size_config[:target_size],
        actual_size: actual_size,
        **result
      }

      cleanup_test_data
    end

    print_summary
  end

  private

  def generate_test_data(target_size)
    restaurants = []
    current_size = 0
    restaurant_id = 1

    while current_size < target_size
      restaurant = generate_restaurant(restaurant_id)
      restaurant_json = restaurant.to_json

      if current_size + restaurant_json.bytesize > target_size
        break
      end

      restaurants << restaurant
      current_size += restaurant_json.bytesize
      restaurant_id += 1
    end

    { "restaurants" => restaurants }
  end

  def generate_restaurant(id)
    {
      "name" => "Test Restaurant #{id} - #{generate_random_cuisine}",
      "menus" => generate_menus
    }
  end

  def generate_menus
    num_menus = rand(2..4)
    menus = []

    num_menus.times do |i|
      menus << {
        "name" => "Menu #{i + 1}",
        "menu_items" => generate_menu_items
      }
    end

    menus
  end

  def generate_menu_items
    num_items = rand(8..15)
    items = []

    num_items.times do |i|
      items << {
        "name" => "Item #{i + 1} - #{generate_random_dish_name}",
        "price" => rand(15.0..120.0).round(2),
        "description" => generate_random_description
      }
    end

    items
  end

  def generate_random_cuisine
    cuisines = [ "Brazilian", "Italian", "Japanese", "Mexican", "French", "Arabic", "Indian", "Thai", "Chinese", "Spanish" ]
    cuisines.sample
  end

  def generate_random_dish_name
    dishes = [ "Picanha", "Sushi", "Pizza", "Tacos", "Risotto", "Paella", "Kebab", "Curry", "Pad Thai", "Dim Sum" ]
    dishes.sample
  end

  def generate_random_description
    descriptions = [
      "Traditional dish prepared with fresh and selected ingredients",
      "Authentic recipe passed down from generation to generation",
      "House specialty with special spices and exclusive sauces",
      "Prepared on the spot with traditional culinary techniques",
      "Unique combination of flavors and textures for an unforgettable gastronomic experience"
    ]
    descriptions.sample
  end

  def benchmark_import(json_data)
    memory_before = get_memory_usage
    gc_stats_before = get_gc_stats

    time_result = Benchmark.measure do
      service = RestaurantImportService.new(json_data)
      @last_result = service.import
    end

    memory_after = get_memory_usage
    gc_stats_after = get_gc_stats

    {
      execution_time: time_result.real,
      cpu_time: time_result.total,
      memory_used: memory_after - memory_before,
      gc_count: gc_stats_after[:count] - gc_stats_before[:count],
      success: @last_result[:success],
      restaurants_processed: @last_result[:data][:restaurants_processed],
      menus_processed: @last_result[:data][:menus_processed],
      items_processed: @last_result[:data][:items_processed],
      errors_count: @last_result[:errors].length,
      logs_count: @last_result[:logs].length
    }
  end

  def get_memory_usage
    if RUBY_PLATFORM.include?('linux')
      `ps -o rss= -p #{Process.pid}`.to_i * 1024
    else
      0
    end
  end

  def get_gc_stats
    {
      count: GC.count,
      heap_allocated_pages: GC.stat[:heap_allocated_pages],
      heap_sorted_pages: GC.stat[:heap_sorted_pages]
    }
  end

  def cleanup_test_data
    Restaurant.where("name LIKE ?", "Test Restaurant%").destroy_all
  end

  def format_size(bytes)
    if bytes >= 1024 * 1024
      "#{(bytes / (1024.0 * 1024.0)).round(2)}MB"
    elsif bytes >= 1024
      "#{(bytes / 1024.0).round(2)}KB"
    else
      "#{bytes}B"
    end
  end

  def print_summary
    puts "\n" + "=" * 80
    puts "📈 PERFORMANCE BENCHMARK SUMMARY"
    puts "=" * 80

    puts "\n#{'Size'.ljust(10)} | #{'Time (s)'.ljust(12)} | #{'Memory (MB)'.ljust(15)} | #{'GC Count'.ljust(10)} | #{'Success'.ljust(8)} | #{'Items'.ljust(8)}"
    puts "-" * 80

    @results.each do |result|
      puts "#{result[:size_name].ljust(10)} | #{result[:execution_time].round(3).to_s.ljust(12)} | #{format_size(result[:memory_used]).ljust(15)} | #{result[:gc_count].to_s.ljust(10)} | #{result[:success].to_s.ljust(8)} | #{result[:items_processed].to_s.ljust(8)}"
    end

    puts "\n" + "=" * 80
    puts "📊 PERFORMANCE ANALYSIS"
    puts "=" * 80

    analyze_performance
  end

  def analyze_performance
    times = @results.map { |r| r[:execution_time] }
    avg_time = times.sum / times.length
    max_time = times.max

    puts "\n⏱️  EXECUTION TIME:"
    puts "   • Average: #{avg_time.round(3)}s"
    puts "   • Maximum: #{max_time.round(3)}s"
    puts "   • Growth: #{((max_time / times.first) * 100).round(1)}% from smallest to largest"

    memories = @results.map { |r| r[:memory_used] }
    avg_memory = memories.sum / memories.length
    max_memory = memories.max

    puts "\n💾 MEMORY USAGE:"
    puts "   • Average: #{format_size(avg_memory)}"
    puts "   • Maximum: #{format_size(max_memory)}"
    puts "   • Efficiency: #{((memories.first / max_memory) * 100).round(1)}% memory efficiency"

    gc_counts = @results.map { |r| r[:gc_count] }
    total_gc = gc_counts.sum

    puts "\n🗑️  GARBAGE COLLECTION (GC):"
    puts "   • Total GCs: #{total_gc}"
    puts "   • Average per test: #{(total_gc / gc_counts.length).round(1)}"

    puts "\n💡 RECOMMENDATIONS:"
    if max_time > 10
      puts "   ⚠️  High execution time - consider processing optimizations"
    end

    if max_memory > 500 * 1024 * 1024 # 500MB
      puts "   ⚠️  High memory usage - consider batch processing"
    end

    if total_gc > 50
      puts "   ⚠️  Too many garbage collections - consider optimizing object allocation"
    end

    if @results.all? { |r| r[:success] }
      puts "   ✅ All tests were successful"
    else
      puts "   ❌ Some tests failed - check error logs"
    end
  end
end

if __FILE__ == $0
  benchmark = UploadPerformanceBenchmark.new
  benchmark.run_benchmark
end
