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

  def report
    players.map do |player|
      id = player[:id]

      {
        name: player[:name],
        handle: player[:handle],
        xp: xp(player_id: id),
        avg_proj_comp: proj_completeness_for_player(player_id: id),
        avg_proj_qual: proj_quality_for_player(player_id: id),
        lrn_supp: learning_support(player_id: id),
        cult_cont: culture_contrib(player_id: id),
        # discern: ,
        # no_proj_rvws:  ,
      }
    end
  end

  def xp(opts = {})
    projects = data.cycle(opts[:cycle_no]).projects(opts[:player_id])

    proj_xps = projects.map do |proj_name, p_data|
      next if opts[:proj_name] && proj_name != opts[:proj_name]

      p_data[:completeness] = proj_completeness(proj_name: proj_name)
      p_data[:quality] = proj_quality(proj_name: proj_name)
      p_data[:total_hours] = proj_hours(proj_name: proj_name)
      p_data[:contribution] = contribution(opts.merge(proj_name: proj_name))

      proj_xp = p_data[:total_hours] \
              * (p_data[:contribution] / 100.0) \
              * (p_data[:completeness] / 100.0) \
              * (p_data[:quality] / 100.0)

      proj_xp.round(2)
    end

    proj_xps.reject(&:nil?).reduce(:+)
  end

  def culture_contrib(opts = {})
    player_id = opts[:player_id]
    cycle_no = opts[:cycle_no]

    scores = data.culture_contrib.subject(player_id).cycle(cycle_no).values(&:to_i)
    mean(scores).to_percent(7)
  end

  def learning_support(opts = {})
    player_id = opts[:player_id]
    cycle_no = opts[:cycle_no]

    scores = data.learning_support.subject(player_id).cycle(cycle_no).values(&:to_i)
    mean(scores).to_percent(7)
  end

  def proj_completeness(opts = {})
    proj_name = opts[:proj_name]

    scores = data.project(proj_name).proj_completeness.values(&:to_i)
    mean(scores).to_percent(100)
  end

  def proj_completeness_for_player(opts = {})
    player_id = opts[:player_id]
    cycle_no = opts[:cycle_no]

    projects = data.cycle(opts[:cycle_no]).projects(opts[:player_id])
    scores = projects.map { |proj_name, _| proj_completeness(proj_name: proj_name) }

    mean(scores).to_percent(100)
  end

  def proj_quality_for_player(opts = {})
    player_id = opts[:player_id]
    cycle_no = opts[:cycle_no]

    projects = data.cycle(opts[:cycle_no]).projects(opts[:player_id])
    scores = projects.map { |proj_name, _| proj_quality(proj_name: proj_name) }

    mean(scores).to_percent(100)
  end

  def proj_quality(opts = {})
    proj_name = opts[:proj_name]

    scores = data.project(proj_name).proj_quality.values(&:to_i)
    mean(scores).to_percent(100)
  end

  def contribution(opts = {})
    player_id = opts[:player_id]
    proj_name = opts[:proj_name]

    scores = data.project(proj_name).contribution.subject(player_id).values(&:to_i)
    mean(scores).to_percent(100)
  end

  def proj_hours(opts = {})
    player_id = opts[:player_id]
    proj_name = opts[:proj_name]

    hours = data.project(proj_name).reporter(player_id).proj_hours.values
    unless hours.all? { |h| h =~ /\A\d+\z/ } # must be nothing but numbers
      raise InvalidHoursValueError, "Can't parse '#{hours}'"
    end

    hours.map(&:to_i).reduce(:+)
  end

  def players(opts = {})
    player_id = opts[:player_id]

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
