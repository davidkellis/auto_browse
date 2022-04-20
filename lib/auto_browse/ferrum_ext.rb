require "ferrum"

# redefing internals for debugging
module Ferrum
  class Browser
    class Command
      def to_a
        command_array = [path] + @flags.map { |k, v| v.nil? ? "--#{k}" : "--#{k}=#{v}" }
        puts "Ferrum::Browser::Command -> #{command_array.join(" ")}"
        command_array
      end
    end
  end
end
