#!/usr/bin/env ruby

require 'json'

json = JSON.parse(File.read(ARGV[0]))

[json["hard_hands"], json["soft_hands"], json["pairs"]].each do |table|
  table.each do |row, cols|
    cols.each do |dealer, cell|
      devs = []
      list_ref = nil
      prev_best = nil
      next_best = nil
      at_tc = nil

      cell.each do |level|
        list = level["actions"].sort_by{|a| a["ev"]}.map{|a| a["action"]}

        if !list_ref.nil? and list != list_ref
          prev_best = list_ref.last
          next_best = list.last
          if !(prev_best == next_best and %w(=).include? prev_best)
            devs << {from: prev_best, to: next_best, at: level["tc"]}
          end
        end
        list_ref = list
      end
      if devs.size > 0
        #puts "#{row} vs #{dealer}: #{prev_best} -> #{next_best} @#{at_tc}"
        printf "%s vs %2s: ", row, dealer
        devs.each do |dev|
          printf "[%s] -> [%s] %+d;  ", dev[:from], dev[:to], dev[:at]
        end
        print "\n"
      end
    end
  end
end
