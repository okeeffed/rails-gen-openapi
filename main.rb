#!/usr/bin/env ruby
require "slop"
require "dry/monads"
require_relative "util/file_helpers"

include Dry::Monads[:result]

verbose = false

opts = Slop.parse { |o|
  o.string "-o", "--output", "output path"
  o.string "-f", "--file", "routes file to read in"
  o.on "-v", "--verbose", "run with verbose info" do
    verbose = true
  end
  o.on "--version", "print the version" do
    puts Slop::VERSION
    exit
  end
}

handle_failure = lambda do |failure|
  puts failure
end

handle_success = lambda do |success|
  puts success
end

# Read file - this looks synchronous
file_data = Util::FileHelpers.call(opts.to_hash[:file])
file_data.either(handle_failure, handle_success)
