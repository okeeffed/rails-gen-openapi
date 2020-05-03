require "dry/monads"
require "dry/monads/do"
require_relative "../structs/rails_route_info.rb"
module Util
  class FileHelpers
    class << self
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # Takes file path and returns RouteInfo based on each line
      # for REST verb, uri_pattern and associated controller_action
      def call(file)
        file_data = yield read(file)
        split_file_data = yield split(file_data)
        stripped_file_data = yield strip(split_file_data)
        route_info = yield create_route_info(stripped_file_data)
        Success(route_info)
      end

      # Simply read the routes file and return data
      def read(file)
        filepath = File.join(File.dirname(__dir__), file)
        file = File.read(filepath)
        Success(file)
      rescue
        Failure("Failed to parse file")
      end

      # Returns string array for each line
      def split(file_content)
        file_lines = file_content.split(/\n/)
        Success(file_lines)
      rescue
        Failure("Failed to split file lines")
      end

      # Accepts string array and maps and strips all whitespace
      def strip(file_content_array)
        arr = file_content_array.map { |line|
          line.strip
        }

        Success(arr)
      rescue
        Failure("Failed to strip white space")
      end

      # Accepts string array from file line
      def create_route_info(stripped_file_data)
        # split on spaces
        route_info_arr = stripped_file_data.map { |line|
          route_info = line.split(/\s+/)
          # ! Is the a way to make this easier to read? Array destructuring?
          Structs::RouteInfo.new(verb: route_info[0], uri_pattern: route_info[1], controller_action: route_info[2])
        }
        Success(route_info_arr)
      rescue
        Failure("Failed to map line content to RouteInfo")
      end
    end
  end
end
