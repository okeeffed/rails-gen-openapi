#!/usr/bin/env ruby
require "slop"
require "dry/monads"
require_relative "util/file"

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

puts opts.to_hash #=> { host: "192.168.0.1", login: "alice", port: 80, verbose: true, quiet: false, check_ssl_certificate: true }

# Read file - this looks synchronous
file_data = FP::RoutesFile.call(opts.to_hash[:file])
result = file_data.value!
puts result
