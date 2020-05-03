#!/usr/bin/env ruby
require "slop"
require "dry/monads"
require_relative "util/file_helpers"
require_relative "util/open_api_helpers"

include Dry::Monads[:result]

# Simple CLI Parsing
opts = Slop.parse { |o|
  o.string "-f", "--file", "routes file to read in"
  o.on "--version", "print the version" do
    puts Slop::VERSION
    exit
  end
}

# Define handlers for Either Monad
handle_failure = lambda do |failure|
  puts failure
  exit 1
end

handle_success = lambda do |success|
  success.map do |info|
    puts info.uri_pattern
  end
  exit 0
end

# Main
# ! Read file - this looks synchronous. How do you write file streams in Ruby?
file_data = Util::FileHelpers.call(opts.to_hash[:file])
# .value_or(handle_failure)
file_data.either(handle_success, handle_failure)
# yaml_format = Util::OpenAPIHelpers.call(file_data)
# yaml_format.either(handle_success, handle_failure)
