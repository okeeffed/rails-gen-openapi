require "dry/monads"
require "dry/monads/do"
require "deep_merge"
require_relative "../structs/open_api"

module Util
  class OpenAPIHelpers
    class << self
      include Dry::Monads[:result]
      include Dry::Monads::Do.for(:call)

      # Takes an array of RouteInfo types and generates the OpenAPI v3 spec
      # to write into YAML and export to a file.
      def call(file_data)
        param_friendly_file_data = yield convert_params_to_compatible_format(file_data)
        paths_hash = yield write_paths_hash(param_friendly_file_data)
        open_api_compliant_hash = yield write_open_api_compliant_hash(paths_hash)

        Success(open_api_compliant_hash)
      end

      def convert_params_to_compatible_format(file_data)
        res = file_data.map { |info|
          # Wanky patter to turn something like /a/b/:param/d
          # to /a/b/{param}/d for OpenAPI standards
          update_string = info.uri_pattern.split("/").map { |uri|
            uri[0] == ":" ? "{#{uri[1..]}}" : uri
          }.join("/")

          Structs::RouteInfo.new(verb: info.verb, controller_action: info.controller_action, uri_pattern: update_string)
        }

        Success(res)
      rescue => e
        # ! Maybe I should be passing the errors as an object with message + stack trace
        puts e
        Failure("Could not convert params from :param to {param} format")
      end

      # ! To be honest, I feel like all of this should be cleaned up.
      # Even if it is just that I need a better formatter to make it read easier.
      # I feel like the following four methods are a bit wtf really.
      def get_request_body_schema
        {type: "object", properties: {id: {type: "string", format: "string"}}}
      end

      def get_verb_with_req_body(info)
        Structs::OpenAPI::VerbWithRequestBody.new(summary: info.controller_action, requestBody: {required: true, content: {"application/json": {schema: get_request_body_schema}}}).attributes
      end

      def get_verb(info)
        Structs::OpenAPI::Verb.new(summary: info.controller_action).attributes
      end

      # ! Better alternative to in-place deep merging? Would rather not use impurities.
      def write_paths_hash(file_data)
        paths_hash = {}
        file_data.each do |info|
          # Simplify the GET part - assume all other REST verbs require a request body
          if info.verb == "GET"
            paths_hash.deep_merge({info.uri_pattern => Hash[info.verb.to_s.downcase, get_verb(info)]})
          else
            paths_hash.deep_merge({info.uri_pattern => Hash[info.verb.to_s.downcase, get_verb_with_req_body(info)]})
          end
        end

        Success(paths_hash)
      rescue => e
        puts e
        Failure("Could not write paths for hash")
      end

      def write_open_api_compliant_hash(paths_hash)
        info = {
          title: "Culture Amp - Performance API",
          description: "Hotfix to add all routes to Postman",
          # Related to v1 API versioning for REST
          version: "1.0.0",
        }
        servers = {url: "http://localhost:7000", description: "Local dev environment"}

        # This ends up the final hash to write to disk.
        open_api_hash = Structs::OpenAPI::Base.new(openapi: "3.0.0", info: info, servers: servers, paths: paths_hash).attributes
        Success(open_api_hash)
      rescue
        Failure("Could not write YAML file")
      end
    end
  end
end
