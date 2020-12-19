require 'open3'
require 'json'
require 'securerandom'

class FreeBJ
  attr_writer :db_dir

  def initialize(bin, bin_args)
    @bin = bin
    @bin_args = bin_args
    @db_dir = nil
  end

  def run(args)
    Open3.popen3(*command_argv(args)) do |stdin, stdout, stderr, t|
      status = t.value.exitstatus
      if status == 2
        return :unable
      end

      if not t.value.success?
        STDERR.puts "Error launching #{command_argv(args)}:"
        STDERR.puts stderr.read
        STDERR.puts "Args: #{command_argv(args).join(" ")}"
        raise "Failed to launch freebj simulator"
      end

      json = stdout.read
      save_db(json) unless @db_dir.nil?
      return JSON.parse(json)
    end
  end

  def get_dry_run(args = [])
    cmd = command_argv(args) << "--dry-run"
    Open3.popen3(*cmd) do |stdin, stdout, stderr, t|
      if not t.value.success?
        STDERR.puts "Error launching #{cmd}:"
        STDERR.puts stderr.read
        STDERR.puts "Args: #{cmd.join(" ")}"
        raise "Failed to launch freebj simulator"
      end
      return JSON.parse(stdout.read)
    end
  end

  def last_saved_id
    @id
  end

private

  def command_argv(args)
    [
      @bin,
      *@bin_args,
      *args
    ]
  end

  def save_db(json)
    @id = SecureRandom.uuid
    dir = @db_dir + "/" + @id[0..1]
    Dir.mkdir(dir) unless Dir.exist? dir
    file_path = "#{dir}/#{@id}.json"
    File.write(file_path, json)
  end
end

def each_hard_hand(downto = 5)
  19.downto(downto).each do |pcard|
    if pcard >= 18
      cards = [10, pcard - 10]
    elsif pcard >= 14
      cards = [9, pcard - 9]
    elsif pcard >= 9
      cards = [7, pcard - 7]
    else
      cards = [2, pcard - 2]
    end

    yield "#{pcard}", cards
  end
end

def each_soft_hand()
  10.downto(2).each do |pcard|
    yield "A#{pcard}", ["A", pcard]
  end
end

def each_pair()
  11.downto(2).each do |pcard|
    pcard = "A" if pcard == 11

    if pcard == 10
      label = "T/T"
    else
      label = "#{pcard}/#{pcard}"
    end

    yield label, [pcard, pcard]
  end
end

def cards_from_str(str)
  if m = str.match(/(\d|T|A)\/\1/)
    c = m[1] == "A" ? "A" : (m[1] == "T" ? 10 : m[1].to_i)
    return [c, c]
  elsif m = str.match(/A(\d+)/)
    c = m[1] == "A" ? "A" : m[1].to_i
    return ["A", c]
  else
    n = str.to_i
    if n >= 18
      return [10, n - 10]
    elsif n >= 14
      return [9, n - 9]
    elsif n >= 9
      return [7, n - 7]
    else
      return [2, n - 2]
    end
  end
end

def rules_to_str(rules)
  surr = {
    "early" => "ESurr",
    "late" => "LSurr",
    false => "NoSurr",
  }[rules["surrender"]]
  db = {
    "any_hand" => "Any",
    "any_two" => "Any2",
    "hard_9-11" => "Hard9-11",
    "hard_10-11" => "Hard10-11",
    false => "None",
  }[rules["double_down"]]

  sprintf(
    '%s/%s/%s/%s/%dD/Sp%d/Db%s/BJ%.2f/P%.2f',
    rules["enhc"] ? "Eu" : "Am",
    rules["h17"] ? "H17" : "S17",
    rules["das"] ? "DAS" : "NoDAS",
    surr,
    rules["decks"],
    rules["max_split_hands"],
    db,
    rules["bj_pays"],
    rules["penetration"]
  )
end

def rules_to_args(rules, exclude_pen: false)
  args = []

  if rules["game_type"] == "ahc"
    args << "--ahc"
  elsif rules["game_type"] == "enhc"
    args << "--enhc"
  end

  if rules["soft17"] == "s17"
    args << "--s17"
  elsif rules["soft17"] == "h17"
    args << "--h17"
  end

  if rules["das"]
    args << "--das"
  else
    args << "--no-das"
  end

  case rules["double_down"]
  when "no_double"; args << "--db-none"
  when "any"; args << "--db-any"
  when "any_two"; args << "--db-any2"
  when "hard_9_to_10"; args << "--db-hard-9-11"
  when "hard_10_to_11"; args << "--db-hard-10-11"
  end

  case rules["surrender"]
  when "no_surrender"; args << "--no-surr"
  when "early_surrender"; args << "--esurr"
  when "late_surrender"; args << "--lsurr"
  end

  args << "-d#{rules["decks"]}"
  args << "--max-splits=#{rules["max_splits"]}"

  args << "-p#{rules["penetration_cards"]}" if !exclude_pen

  if rules["play_ace_pairs"]
    args << "--playAA"
  else
    args << "--no-playAA"
  end

  args
end
