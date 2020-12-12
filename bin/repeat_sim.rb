#!/usr/bin/env ruby

require 'getoptlong'
require_relative './freebj'

opts = GetoptLong.new(
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--run",               GetoptLong::REQUIRED_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
)

bin = "freebj"
bin_args = []
num_runs = 10

def usage
  STDERR.puts "Usage: #{$0} [OPTION...]\n"
end

opts.each do |opt, arg|
  case opt
  when "--freebj-bin"
    bin = arg

  when "--run"
    num_runs = arg.to_i

  when "--help"
    usage
    exit 0
  end
end
bin_args = ARGV

$freebj = FreeBJ.new(bin, bin_args)

num_runs.times do |i|
  res = $freebj.run([])
  printf "%.10f;%.10f\n", res["ev"], res["stddev"]
  STDERR.printf "  %5d / %d\n", i + 1, num_runs
end
