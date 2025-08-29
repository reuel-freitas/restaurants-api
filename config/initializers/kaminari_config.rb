# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 10
  config.window = 2
  config.outer_window = 1
  config.left = 1
  config.right = 1
end
