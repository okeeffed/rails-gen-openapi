require "dry/monads"
require "dry/monads/do"
require_relative "../structs/rails_route_info.rb"

module Util
  class OpenAPIHelpers
    class << self
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # Takes an array of RouteInfo types and generates the OpenAPI v3 spec
      # to write into YAML and export to a file.
      def call(file)
      end

      def write_open_api_yaml(specification)
        # TODO
      end
    end
  end
end
