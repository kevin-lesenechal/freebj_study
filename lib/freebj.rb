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
