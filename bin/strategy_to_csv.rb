#!/usr/bin/ruby

require 'json'
require 'csv'
require_relative 'freebj'

json = JSON.parse($stdin.read)

CSV($stdout) do |csv|
  csv << [rules_to_str(json["rules"])]

  [json["hard_hands"], json["soft_hands"], json["pairs"]].each do |data|
    data.each do |row, data|
      data.each do |dealer, tcs|


        row_n = tcs.map{|tc| tc["actions"].size}.max
        row_n.times do |row_i|
          if row_i == 0
            csv_row = [row, dealer]
          else
            csv_row = ["", ""]
          end

          tcs.each do |tc|
            csv_row << tc["actions"][row_i]["action"] << tc["actions"][row_i]["ev"]
          end

          csv << csv_row
        end
      end
      csv << []
    end
    csv << []
  end
end
