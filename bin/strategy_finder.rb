#!/bin/env ruby

$:.push File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'getoptlong'
require 'json'
require 'freebj'

opts = GetoptLong.new(
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
  ["--holecarding",       GetoptLong::NO_ARGUMENT],
)

$options = {
  actions: nil,
  devs: nil,
  tc_min: 0,
  tc_max: 0,
  holecarding: false,
}

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

    when "--holecarding"
      $options[:holecarding] = true
  end
end

bin_args = ARGV
#18/4
$freebj = FreeBJ.new(bin, bin_args)
dry_run = $freebj.get_dry_run()
json = {
  rounds: dry_run["rounds"],
  rules: dry_run["rules"],
  hard_hands: {},
  soft_hands: {},
  pairs: {}
}

def to_test(label, dealer)
  return true
end

def do_test_cell(player, dealer)
  best_ev = nil
  best_action = nil
  out = {}

  $options[:tc_min].upto($options[:tc_max]).each do |tc|
    out[tc] = {}

    %w(+ = D V #).each do |action|
      STDERR.printf "\e[90m%+d%s\e[0m", tc, action

      raise "TC != 0 not implemented" if tc != 0

      res = $freebj.run([
        "-a", action,
        "-c", player.join(","),
        "--dealer", dealer.join(",")
      ])

      if res != :unable
        out[tc][action] = {"ev": res["ev"], "stddev": res["stddev"]}
        if tc == 0 and (best_ev.nil? or res["ev"] > best_ev)
          best_ev = res["ev"]
          best_action = action
        end
      end
      STDERR.print ("\e[D" * 3)
    end

    out[tc] = out[tc].collect{|a| {action: a[0], **a[1]}}.sort_by{|a| a[:ev]}.reverse
  end

  out = out.collect{|x| {tc: x[0].to_s.to_i, actions: x[1]}}

  case best_action
    when "+"; STDERR.print "\e[32m"
    when "="; STDERR.print "\e[91m"
    when "D"; STDERR.print "\e[94m"
    when "V"; STDERR.print "\e[93m"
  end
  STDERR.print " #{best_action} "

  return out
end

def do_test_line(row_label, player, out)
  STDERR.printf "\e[97m%3s │\e[0m", row_label
  out[row_label] = {}

  if $options[:holecarding]
    dealer_cards = [[2, 2], [2, 3], [2, 4], [2, 5], [2, 6], [2, 7], [2, 8],
                    [2, 9], [9, 3], [9, 4], [9, 5], [9, 6], [9, 7], [9, 8],
                    [9, 9], [10, 9], [10, 10], ["A", "A"], ["A", 2], ["A", 3],
                    ["A", 4], ["A", 5], ["A", 6], ["A", 7], ["A", 8], ["A", 9]]
  else
    dealer_cards = 2.upto(11).map{|c| [c == 11 ? "A" : c.to_s]}
  end

  dealer_cards.each do |dcards|
    dcard = 1 if dcard == 11
    dcard_label = dcard.to_s
    dcard_label = "A" if dcard_label == "1"

    if $options[:holecarding]
      if dcards[0] == "A"
        dcard_label = "A#{dcards[1]}"
      else
        dcard_label = dcards.sum
      end
    else
      dcard_label = dcards[0]
    end

    if !to_test(row_label, dcard)
      STDERR.print "   "
      next
    end

    out[row_label][dcard_label] = do_test_cell(player, dcards)
  end

  out.delete(row_label) if out[row_label].empty?

  STDERR.printf "\e[97m│ %s\e[0m\n", row_label
end

begin
  STDERR.print "\e[97m"
  if $options[:holecarding]
    STDERR.print "      4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 AA A2 A3 A4 A5 A6 A7 A8 A9\n"
    STDERR.print "    ┌──────────────────────────────────────────────────────────────────────────────┐\n\e[0m"
  else
    STDERR.print "      2  3  4  5  6  7  8  9  10 A\n"
    STDERR.print "    ┌──────────────────────────────┐\n\e[0m"
  end

  begin
    each_hard_hand(8) do |label, player|
      do_test_line(label, player, json[:hard_hands])
    end
  rescue Interrupt
    if $options[:holecarding]
      STDERR.print "\n\e[97m"
      STDERR.print "    └──────────────────────────────────────────────────────────────────────────────┘\e[0m\n"
    else
      STDERR.print "\n\e[97m"
      STDERR.print "    └──────────────────────────────┘\e[0m\n"
    end
    raise
  end

  STDERR.print "\e[97m"
  if $options[:holecarding]
    STDERR.print "    └──────────────────────────────────────────────────────────────────────────────┘\n"
    STDERR.print "      4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 AA A2 A3 A4 A5 A6 A7 A8 A9\n"
    STDERR.print "    ┌──────────────────────────────────────────────────────────────────────────────┐\n\e[0m"
  else
    STDERR.print "    └──────────────────────────────┘\n"
    STDERR.print "      2  3  4  5  6  7  8  9  10 A\n"
    STDERR.print "    ┌──────────────────────────────┐\n\e[0m"
  end

  begin
    each_soft_hand do |label, player|
      do_test_line(label, player, json[:soft_hands])
    end
  rescue Interrupt
    if $options[:holecarding]
      STDERR.print "\n\e[97m"
      STDERR.print "    └──────────────────────────────────────────────────────────────────────────────┘\e[0m\n"
    else
      STDERR.print "\n\e[97m"
      STDERR.print "    └──────────────────────────────┘\e[0m\n"
    end
    raise
  end

  STDERR.print "\e[97m"
  if $options[:holecarding]
    STDERR.print "    └──────────────────────────────────────────────────────────────────────────────┘\n"
    STDERR.print "      4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 AA A2 A3 A4 A5 A6 A7 A8 A9\n"
    STDERR.print "    ┌──────────────────────────────────────────────────────────────────────────────┐\n\e[0m"
  else
    STDERR.print "    └──────────────────────────────┘\n"
    STDERR.print "      2  3  4  5  6  7  8  9  10 A\n"
    STDERR.print "    ┌──────────────────────────────┐\n\e[0m"
  end

  begin
    each_pair do |label, player|
      do_test_line(label, player, json[:pairs])
    end
  rescue Interrupt
    STDERR.print "\n"
    raise
  ensure
    STDERR.print "\e[97m"
    if $options[:holecarding]
      STDERR.print "    └──────────────────────────────────────────────────────────────────────────────┘\e[0m\n"
    else
      STDERR.print "    └──────────────────────────────┘\e[0m\n"
    end
  end
rescue Interrupt
ensure
  puts JSON.pretty_generate(json)
end
