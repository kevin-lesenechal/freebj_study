#!/usr/bin/env ruby

$:.push File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'open3'
require 'json'
require 'getoptlong'
require 'freebj'

opts = GetoptLong.new(
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--db-dir",            GetoptLong::REQUIRED_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
)

bin = "freebj"
bin_args = []
db_dir = "data/simulations"

def usage
  STDERR.puts "Usage: #{$0} [OPTION...]\n"
end

opts.each do |opt, arg|
  case opt
  when "--freebj-bin"
    bin = arg

  when "--db-dir"
    db_dir = arg

  when "--help"
    usage
    exit 0
  end
end
bin_args = ARGV

$freebj = FreeBJ.new(bin, bin_args)
$freebj.db_dir = db_dir

ROW_FILTER = nil
COL_FILTER = nil

json_output = {
  rounds: nil,
  rules: {},
  hard_hands: {},
  soft_hands: {},
  pairs: {}
}

def run_freebj(player_cards, dealer_card)
  player_cards.map!{|c| c == 1 ? "A" : c }
  dealer_card = "A" if dealer_card == 1

  return $freebj.run([
    "-c", player_cards.join(","),
    "--dealer=#{dealer_card}"
  ])
end

def do_test(player_cards, dealer_card, row_card, out)
  col_label = dealer_card == 1 ? "A" : dealer_card.to_s
  if !COL_FILTER.nil? and !COL_FILTER.include? col_label
    STDERR.print " " * (dealer_card == 1 ? 6 : 7)
    return
  end

  res = run_freebj(player_cards, dealer_card)

  if res["ev"] >= 0.1
    color = "\e[32m"
  elsif res["ev"] <= -0.1
    color = "\e[31m"
  else
    color = ""
  end

  STDERR.printf "%s%+.2f\e[0m%s", color, res["ev"], dealer_card == 1 ? " " : "  "
  out["ev"] = res["ev"]
  out["stddev"] = res["stddev"]
  out["ref"] = $freebj.last_saved_id
end

def do_test_line(player_cards, row_card, out)
  return if !ROW_FILTER.nil? and !ROW_FILTER.include? row_card

  out[row_card] = {}

  STDERR.printf "\e[97m%3s │\e[0m ", row_card
  2.upto(11).each do |dcard|
    dcard = 1 if dcard == 11
    out[row_card][dcard == 1 ? "A" : dcard.to_s] = {}
    do_test(player_cards, dcard, row_card, out[row_card][dcard == 1 ? "A" : dcard.to_s])
  end
  STDERR.printf "\e[97m│ %s\e[0m\n", row_card
end

dry_run = $freebj.get_dry_run()
json_output[:rounds] = dry_run["rounds"]
json_output[:rules] = dry_run["rules"]

STDERR.print "\e[97m"
STDERR.print "        2      3      4      5      6      7      8      9     10      A\n"
STDERR.print "    ┌──────────────────────────────────────────────────────────────────────┐\n\e[0m"

19.downto(5).each do |pcard|
  if pcard >= 18
    cards = [10, pcard - 10]
  elsif pcard >= 14
    cards = [9, pcard - 9]
  elsif pcard >= 9
    cards = [7, pcard - 7]
  else
    cards = [2, pcard - 2]
  end
  raise "No pair allowed (#{cards[0]})" if cards[0] == cards[1] and cards[0] != 10

  do_test_line(cards, "#{pcard}", json_output[:hard_hands])
end

STDERR.print "\e[97m"
STDERR.print "    └──────────────────────────────────────────────────────────────────────┘\n"
STDERR.print "        2      3      4      5      6      7      8      9     10      A\n"
STDERR.print "    ┌──────────────────────────────────────────────────────────────────────┐\n\e[0m"

10.downto(2).each do |pcard|
  do_test_line([1, pcard], "A#{pcard}", json_output[:soft_hands])
end

STDERR.print "\e[97m"
STDERR.print "    └──────────────────────────────────────────────────────────────────────┘\n"
STDERR.print "        2      3      4      5      6      7      8      9     10      A\n"
STDERR.print "    ┌──────────────────────────────────────────────────────────────────────┐\n\e[0m"

11.downto(2).each do |pcard|
  pcard = 1 if pcard == 11

  if pcard == 1
    label = "A/A"
  elsif pcard == 10
    label = "T/T"
  else
    label = "#{pcard}/#{pcard}"
  end

  do_test_line([pcard, pcard], label, json_output[:pairs])
end

STDERR.print "\e[97m"
STDERR.print "    └──────────────────────────────────────────────────────────────────────┘\e[0m\n"

def print_csv(table)
  table.each do |row_card, values|
    if row_card == "20" or row_card == "A10"
      STDOUT.puts ";2;3;4;5;6;7;8;9;10;A"
    end

    STDOUT.printf(
      "%s;%s\n",
      row_card,
      values.map{|v| sprintf("%.6f", v) }.join(";")
    )
  end
end

puts JSON.pretty_generate(json_output)
