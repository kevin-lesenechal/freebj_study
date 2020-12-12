#!/bin/env ruby

require 'getoptlong'
require_relative './freebj'

opts = GetoptLong.new(
  ["--actions",     "-a", GetoptLong::REQUIRED_ARGUMENT],
  ["--devs",        "-d", GetoptLong::REQUIRED_ARGUMENT],
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
)

$options = {
  actions: nil,
  devs: nil
}

bin = "freebj"
bin_args = []

def usage
  STDERR.puts "Usage: #{$0} [OPTION...]\n"
  STDERR.puts "OPTIONS"
  STDERR.puts "    --actions=ACTIONS, -a ACTIONS"
  STDERR.puts "        ..."
end

opts.each do |opt, arg|
  case opt
  when "--actions"
    $options[:actions] = arg.split(",").map do |a|
      label = {
        "+" => "HIT",
        "=" => "STAND",
        "D" => "DOUBLE",
        "V" => "SPLIT",
        "#" => "SURRENDER",
      }[a]
      if a == "*"
        next ["BASIC STRAT.", []]
      end
      raise "Invalid action" if label.nil?
      next [label, ["-a", a]]
    end

  when "--devs"
  when "--freebj-bin"
    bin = arg

  when "--help"
    usage
    exit 0
  end
end
bin_args = ARGV

if $options[:actions].nil?
  STDERR.puts "#{$0}: no actions specified"
  usage
  exit 1
end

$freebj = FreeBJ.new(bin, bin_args)

#p $options[:actions]
#exit

#ACTIONS = [["HIT", "-a+"], ["STAND", "-a="], ["SPLIT", "-aY"], ["SURRENDER", "-a#"]]
DEV_ACTION = "D"
actions = [1, 3, 5, 7].map{|n| ["#{DEV_ACTION} @ TC ≥#{n}", "--dev-override=>#{n}#{DEV_ACTION}"] }
ACTIONS = [["NO DEV", ""]] + actions

RULES = [
  [["S17", ""], ["H17", "--h17"]],
  [["ENHC", ""], ["AHC", "--holecard"]]
]

def each_ruleset(rules)
  if rules.size == 1
    rules[0].each do |r0|
      yield [r0]
    end
  elsif rules.size == 2
    rules[0].each do |r0|
      rules[1].each do |r1|
        yield [r0, r1]
      end
    end
  elsif rules.size == 3
    rules[0].each do |r0|
      rules[1].each do |r1|
        rules[2].each do |r2|
          yield [r0, r1, r2]
        end
      end
    end
  else
    raise "Unsupported"
  end
end

printf "\e[97m%15s │", ""
$options[:actions].each do |action|
  printf " %s │", action[0].center(15)
end
print "\n"
printf "%15s ├", ""
$options[:actions].size.times do |n|
  printf "%s%s", "─" * 17, n == $options[:actions].size - 1 ? "┤" : "┼"
end
print "\e[0m\n"

each_ruleset(RULES) do |ruleset|
  args = ruleset.map{|x| x[1]}.reject{|r| r.empty?}
  label = ruleset.map{|x| x[0]}.join("/")

  printf "\e[97m%15s │\e[0m ", label
  evs = []
  $options[:actions].each do |action|
    action_args = action[1]
    action_args = [action_args] if !action_args.is_a? Array
    res = $freebj.run(args + action_args)
    evs << res["ev"]
    printf "%+7.4f  \e[90m%.4f\e[0m \e[97m│\e[0m ", res["ev"], res["stddev"]
  end
  max_ev_index = evs.each_with_index.max[1]
  print "\e[D" * ((evs.size - max_ev_index) * 18)
  printf "\e[32m%+7.4f\e[0m", evs[max_ev_index]
  print "\n"
end
