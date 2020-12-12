#!/usr/bin/ruby

require 'json'

ARGV.each do |file|
  j = JSON.parse(File.read(file))

  [j["hard_hands"], j["soft_hands"], j["pairs"]].each do |table|
    table.each do |row_label, row|
      row.each do |col_label, actions|
        row[col_label] = [
          {
            "tc": 0,
            "actions": actions.map{|k, v| {"action": k, **v}}.sort_by{|a| a["ev"]}.reverse
          }
        ]
      end
    end
  end

  File.write(file, JSON.pretty_generate(j) + "\n")
end
