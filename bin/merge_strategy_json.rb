#!/usr/bin/ruby

require 'json'

def merge_jsons(a, b)
  if a[:rules] != b[:rules]
    raise "Rules do not match"
  end

  %w(hard_hands soft_hands pairs).each do |hands_type|
    next unless b.key? hands_type
    b[hands_type].each do |row, b_data|
      b_data.each do |dealer, b_data|
        if a[hands_type].key? row and a[hands_type][row].key? dealer
          raise "Duplicate data, row=#{row}, dealer=#{dealer}"
        end
        if not a[hands_type].key? row
          a[hands_type][row] = {}
        end
        a[hands_type][row][dealer] = b_data
      end
    end
  end

  return a
end

if ARGV.size == 0
  raise "Expecting JSON input files"
end

out = JSON.parse(File.read(ARGV.shift))

ARGV.each do |file|
  out = merge_jsons(out, JSON.parse(File.read(file)))
end

puts JSON.pretty_generate(out)
