#!/usr/bin/env ruby
require "slop"
require "dry/monads"
require "yaml"
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

# ! This hack sucks - what is better? hash.transform_keys(&:to_s) didn't help me on 2.6.6.
class ::Hash
  # via https://stackoverflow.com/a/25835016/2257038
  def stringify_keys
    h = map { |k, v|
      v_str = if v.instance_of? Hash
        v.stringify_keys
      else
        v
      end

      [k.to_s, v_str]
    }
    Hash[h]
  end
end

# Define handlers for Either Monad
handle_failure = lambda do |failure|
  puts failure
  exit 1
end

handle_success = lambda do |success|
  res = success.to_hash.stringify_keys

  # Write OpenAPI output to YAML file
  # puts success
  File.open("temp.yml", "w") { |file| file.write(res.to_yaml) }
  exit 0
end

# Main
# ! Read file - this looks synchronous. How do you write file streams in Ruby instead of creating large memory buffers?
file_data = Util::FileHelpers.call(opts.to_hash[:file]).value_or(handle_failure)
yaml_format = Util::OpenAPIHelpers.call(file_data)

# Fork either handlers based on success or failure
yaml_format.either(handle_success, handle_failure)
