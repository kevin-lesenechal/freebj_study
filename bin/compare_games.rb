#!/usr/bin/env ruby

require 'json'
require 'csv'

SAMPLES = "10G"
GAMES_DIR = "data/game"

def find_game(rules)
  name = "game_#{SAMPLES}_#{rules[:game_type]}_#{rules[:soft17]}"
  name += "_d#{rules[:decks]}"
  name += "_#{rules[:surr]}" if rules[:surr]
  name += "_das" if rules[:das]

  file_path = "#{GAMES_DIR}/#{name}.json"

  return JSON.parse(File.read(file_path))
end

def rules_label(rules)
  label = rules[:game_type] == "enhc" ? "Eu" : "Am"
  label += "/" + (rules[:soft17] == "h17" ? "H17" : "S17")
  label += "/" + (rules[:das] ? "DAS" : "NoDAS")
  if rules[:surr] == "esurr"
    label += "/ESurr"
  elsif rules[:surr] == "lsurr"
    label += "/LSurr"
  else
    label += "/NoSurr"
  end

  return label
end

def print_line(rules, csv)
  row = []
  row << rules_label(rules)

  1.upto(8).each do |decks|
    game = find_game({**rules, decks: decks})
    if game.nil?
      row << nil
    else
      row << game["ev"]
    end
  end

  csv << row
end

csv = CSV.new($stdout)

csv << [nil] + 1.upto(8).to_a

%w(enhc ahc).each do |game_type|
  %w(s17 h17).each do |soft17|
    [false, true].each do |das|
      print_line({
        game_type: game_type,
        soft17: soft17,
        das: das,
        surr: false
      }, csv)
    end
  end
end
