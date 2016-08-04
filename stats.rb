require 'csv'

require_relative './game_data.rb'
require_relative './utils.rb'

class InvalidHoursValueError < StandardError; end
class MissingOptionError < StandardError; end

class Stats
  include Aggregates

  attr_reader :data

  def initialize(*files)
    @data = GameData.import(files)
  end

  def stat_names
    %w[ xp avg_proj_comp avg_proj_qual lrn_supp cult_cont discern no_proj_rvws ]
  end

  def report(player_id=nil)
    data.get_players(player_id).map do |player|
      id = player[:id]

      {
        name: player[:name],
        handle: player[:handle],
        xp: xp(player_id: id),
        avg_proj_comp: proj_completeness_for_player(player_id: id),
        avg_proj_qual: proj_quality_for_player(player_id: id),
        lrn_supp: learning_support(player_id: id),
        cult_cont: culture_contrib(player_id: id),
        discern: discernment(player_id: id),
        no_proj_rvws: no_proj_reviews(player_id: id)
      }
    end
  end

  def xp(opts = {})
    projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

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

    projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])
    scores = projects.map { |proj_name, _| proj_completeness(proj_name: proj_name) }

    mean(scores).to_percent(100)
  end

  def proj_quality_for_player(opts = {})
    player_id = opts[:player_id]
    cycle_no = opts[:cycle_no]

    projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])
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

  def self_reported_contribution(opts = {})
    data.self_reported_contribution(opts[:player_id], opts[:proj_name])
        .values(&:to_i)
        .first
        .to_percent(100)
  end

  def team_reported_contribution(opts = {})
    scores= data.team_reported_contribution(opts[:player_id], opts[:proj_name])
                .values(&:to_i)

    mean(scores).to_percent(100)
  end

  def discernment(opts = {})
    projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

    proj_discernments = projects.map do |proj_name, p_data|
      next if opts[:proj_name] && proj_name != opts[:proj_name]

      p_data[:self_rep_contrib] = self_reported_contribution(opts.merge(proj_name: proj_name))
      p_data[:team_rep_contrib] = team_reported_contribution(opts.merge(proj_name: proj_name))

      proj_discernment = p_data[:self_rep_contrib] - p_data[:team_rep_contrib]
      proj_discernment.abs
    end

    mean(proj_discernments.reject(&:nil?)).round(2)
  end

  def contribution_dissonance(opts = {})
    contribution(opts) - expected_contribution(opts)
  end

  def expected_contribution(opts = {})
    raise MissingOptionError, :proj_name unless opts[:proj_name]

    (1 / data.team_size(opts[:proj_name]).to_f).round(2)
  end

  def proj_hours(opts = {})
    player_id = opts[:player_id]
    proj_name = opts[:proj_name]

    hours = data.project(proj_name).reporter(player_id).proj_hours.values
    hours.map(&:to_i).reduce(:+)
  end

  def no_proj_reviews(opts = {})
    data.cycle(opts[:cycle_no])
        .reporter(opts[:player_id])
        .proj_completeness
        .count
  end

  # Helper queries

  def projects(opts = {})
    data.cycle(opts[:cycle_no])
        .get_projects(opts[:player_id])
  end

  def cycles
    data.cycles
  end
end

if $PROGRAM_NAME == __FILE__
  require 'pry'

  s = Stats.new(*ARGV)
  binding.pry
end
