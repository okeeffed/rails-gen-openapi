require "dry-struct"
require_relative "../types/index"

module Structs
  module OpenAPI
    class Base < Dry::Struct
      # Unsure how coercion parsing goes for semantic versioning
      attribute :openapi, Types::String
      # ! Should this use Types::Hash.schema instead?
      attribute :info, Types::Hash.schema(
        title: Types::Strict::String,
        description: Types::Strict::String,
        version: Types::String
      )
      attribute :servers, Types::Hash.schema(
        url: Types::Strict::String,
        description: Types::Strict::String,
      )
      # General collectio of paths ie /user etc
      attribute :paths, Types::Strict::Hash
    end

    class VerbWithRequestBody < Dry::Struct
      attribute :summary, Types::Strict::String
      attribute :requestBody, Types::Hash.schema(
        required: Types::Strict::Bool,
        content: Types::Hash.schema(
          "application/json": Types::Hash.schema(
            schema: Types::Hash.schema(
              type: Types::Strict::String,
              properties: Types::Hash.schema(
                id: Types::Hash.schema(
                  type: Types::Strict::String,
                  format: Types::Strict::String
                )
              )
            )
          )
        )
      )
    end

    class Verb < Dry::Struct
      attribute :summary, Types::Strict::String
    end
  end
end
