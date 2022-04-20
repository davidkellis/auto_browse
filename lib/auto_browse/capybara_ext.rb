require "capybara"

module Capybara::Node::Finders
  def find?(*args, **options, &optional_filter_block)
    find(*args, **options, &optional_filter_block)
  rescue => e
    puts "error: #{e.message}"
    nil
  end
end
