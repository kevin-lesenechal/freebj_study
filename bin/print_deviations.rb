#!/usr/bin/env ruby

require 'json'
require 'csv'

json = JSON.parse(File.read(ARGV[0]))

devs = json["deviations"].sort_by{|k, v| v["ev_diff"] }.reverse

CSV($stdout) do |csv|
  devs.each do |label, dev|
    if dev["trigger"] == "above_equal"
      trigger = ">"
    elsif dev["trigger"] == "under_equal"
      trigger = "<"
    else
      raise "Unknown trigger"
    end

    override = "#{label}:#{trigger}#{dev["tc"]}#{dev["new_action"]}"

    csv << [
      override,
      sprintf("%+.8f", dev["ev_diff"]),
      sprintf("%+.8f", dev["stddev_diff"])
    ]
  end
end
