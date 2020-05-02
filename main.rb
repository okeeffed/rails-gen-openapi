#!/usr/bin/env ruby
require "slop"

opts = Slop.parse { |o|
  o.string "-o", "--output", "output path"
  o.on "--version", "print the version" do
    puts Slop::VERSION
    exit
  end
}

puts opts.to_hash #=> { host: "192.168.0.1", login: "alice", port: 80, verbose: true, quiet: false, check_ssl_certificate: true }
