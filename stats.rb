require 'csv'

require_relative './game_data.rb'

module Aggregates
  def mean(nums)
    nums.reduce(:+) / nums.count.to_f
  end
end

class Numeric
  def to_percent(limit, decimal = 2)
    ((self / limit.to_f) * 100).round(decimal)
  end
end

class InvalidHoursValueError < StandardError; end

class Stats
  include Aggregates

  attr_reader :data

  def initialize(*files)
    @data = GameData.import(files)
  end

  def culture_contrib(opts = {})
    player_id = opts.fetch(:player_id)
    cycle_no = opts.fetch(:cycle_no)

    scores = data.culture_contrib.receiver(player_id).cycle(cycle_no).values(&:to_i)
    mean(scores).to_percent(7)
  end

  def learning_support(opts = {})
    player_id = opts.fetch(:player_id)
    cycle_no = opts.fetch(:cycle_no)

    scores = data.learning_support.receiver(player_id).cycle(cycle_no).values(&:to_i)
    mean(scores).to_percent(7)
  end

  def proj_completeness(opts = {})
    proj_name = opts.fetch(:proj_name)

    scores = data.project(proj_name).proj_completeness.values(&:to_i)
    mean(scores).to_percent(100)
  end

  def proj_quality(opts = {})
    proj_name = opts.fetch(:proj_name)

    scores = data.project(proj_name).proj_quality.values(&:to_i)
    mean(scores).to_percent(100)
  end

  def contribution(opts = {})
    player_id = opts.fetch(:player_id)
    proj_name = opts.fetch(:proj_name)

    scores = data.project(proj_name).contribution.receiver(player_id).values(&:to_i)
    mean(scores).to_percent(100)
  end

  def proj_hours(opts = {})
    player_id = opts.fetch(:player_id)
    proj_name = opts.fetch(:proj_name)

    hours = data.project(proj_name).giver(player_id).proj_hours.values.first
    unless hours =~ /\A\d+\z/ # must be nothing but numbers
      raise InvalidHoursValueError, "Can't parse '#{hours}'"
    end

    hours.to_i
  end

  def players(opts = {})
    player_id = opts.fetch(:player_id, nil)

    players = data.players
    return players unless player_id

    players.find { |player| player[:id] == player_id }
  end
end

if $PROGRAM_NAME == __FILE__
  require 'pry'

  s = Stats.new(*ARGV)
  binding.pry
end
