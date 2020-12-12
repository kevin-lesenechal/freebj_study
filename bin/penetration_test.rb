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

1.upto(100) do |pen|
  res = $freebj.run(["-p", "#{pen}%"])
  printf "%.2f;%.10f;%.10f\n", pen / 100.0, res["ev"], res["stddev"]
end
