#!/usr/bin/env ruby

require 'getoptlong'
require_relative './freebj'

opts = GetoptLong.new(
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
)

bin = "freebj"
bin_args = []

def usage
  STDERR.puts "Usage: #{$0} [OPTION...]\n"
end

opts.each do |opt, arg|
  case opt
  when "--freebj-bin"
    bin = arg

  when "--help"
    usage
    exit 0
  end
end
bin_args = ARGV

$freebj = FreeBJ.new(bin, bin_args)

1.upto(30) do |spread|
  res = $freebj.run(["--bet-spread", "#{spread}"])
  printf "%d;%.10f;%.10f\n", spread, res["ev"], res["stddev"]
end
