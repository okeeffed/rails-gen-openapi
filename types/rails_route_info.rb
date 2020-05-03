require "dry-types"
require "dry-struct"

module Types
  include Dry.Types()

  class RouteInfo < Dry::Struct
    attribute :verb, Types::Strict::String
    attribute :uri_pattern, Types::Strict::String
    attribute :controller_action, Types::Strict::String
  end
end
