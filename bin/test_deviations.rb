#!/usr/bin/env ruby

$:.push File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'getoptlong'
require 'json'
require 'freebj'

opts = GetoptLong.new(
  ["--freebj-bin",  "-b", GetoptLong::REQUIRED_ARGUMENT],
  ["--db-dir",            GetoptLong::REQUIRED_ARGUMENT],
  [                 "-n", GetoptLong::REQUIRED_ARGUMENT],
  ["--no-save",           GetoptLong::NO_ARGUMENT],
  ["--help",        "-h", GetoptLong::NO_ARGUMENT],
)

bin = "freebj"
bin_args = []
$db_dir = "data/simulations"
rounds = nil

def usage
  STDERR.puts "Usage: #{$0} [OPTION...]\n"
end

opts.each do |opt, arg|
  case opt
    when "--freebj-bin"
      bin = arg

    when "--db-dir"
      $db_dir = arg

    when "--no-save"
      $db_dir = nil

    when "-n"
      rounds = arg

    when "--help"
      usage
      exit 0
  end
end

if ARGV.size != 1
  usage
  exit 1
end

dev_file = ARGV[0]

$freebj = FreeBJ.new(bin, bin_args)
$freebj.db_dir = $db_dir

json = JSON.parse(File.read(dev_file))

rules = json["rules"]
rules["surrender"] = "no_surrender"

args = rules_to_args(rules, exclude_pen: true)

if rounds.nil?
  rounds = json["rounds"]
end

args += ["-n", rounds.to_s, "-j16", "-p", "95%"]

begin
  json["deviations"].each do |label, dev|
    if dev["trigger"] == "above_equal"
      trigger = ">"
    elsif dev["trigger"] == "under_equal"
      trigger = "<"
    else
      raise "Unknown trigger"
    end

    override = "#{label}:#{trigger}#{dev["tc"]}#{dev["new_action"]}"

    m = label.match(/(.+)vs(.+)/)
    cards = cards_from_str(m[1]).join(",")
    dealer = m[2]

    printf "%-11s  ", override

    if !dev["with"].nil?
      puts "*"
      next
    end

    without = $freebj.run(args + ["--hilo"])
    without_ref = $freebj.last_saved_id
    with = $freebj.run(args + ["--hilo", "-D", override])
    with_ref = $freebj.last_saved_id

    without = {
      "ev" => without["ev"],
      "stddev" => without["stddev"],
      "ref" => without_ref,
    }
    with = {
      "ev" => with["ev"],
      "stddev" => with["stddev"],
      "ref" => with_ref,
    }

    ev_diff = with["ev"] - without["ev"]
    stddev_diff = with["stddev"] - without["stddev"]

    dev["without"] = without
    dev["with"] = with
    dev["ev_diff"] = ev_diff
    dev["stddev_diff"] = stddev_diff

    printf "%+.4f -> %+.4f    %+.4f\n", without["ev"], with["ev"], ev_diff
  end
ensure
  File.write(dev_file, JSON.pretty_generate(json))
end
