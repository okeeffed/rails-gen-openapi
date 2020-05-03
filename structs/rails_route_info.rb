require "dry-struct"
require_relative "../types/index"

module Structs
  class RouteInfo < Dry::Struct
    attribute :verb, Types::Strict::String
    attribute :uri_pattern, Types::Strict::String
    attribute :controller_action, Types::Strict::String
  end
end
