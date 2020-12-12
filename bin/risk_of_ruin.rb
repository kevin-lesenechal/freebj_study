#!/bin/env ruby

require_relative './freebj'
require 'getoptlong'

opts = GetoptLong.new(
  ["--freebj-bin", "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--help",       "-h", GetoptLong::NO_ARGUMENT],
  ["--jobs",       "-j", GetoptLong::REQUIRED_ARGUMENT],
  ["--samples",    "-s", GetoptLong::REQUIRED_ARGUMENT],
)

samples = 100_000
freebj_bin = "freebj"
jobs = 16

opts.each do |opt, arg|
  case opt
  when "--samples"
    samples = arg.to_i

  when "--freebj-bin"
    freebj_bin = arg

  when "--help"
    usage
    exit 0

  when "--jobs"
    jobs = arg.to_i
  end
end

freebj = FreeBJ.new(freebj_bin, ARGV)
ruin_count = 0

per_thread = samples / jobs
threads = []

jobs.times do
  threads << Thread.new do
    per_thread.times do
      sim_res = freebj.run([])

      if sim_res["bankroll"]["min"] <= 0
        ruin_count += 1
      end
    end
  end
end

threads.each{|t| t.join}

printf "%7d / %7d  (%.1f %%)\n", ruin_count, samples, (ruin_count.to_f / samples * 100.0)
