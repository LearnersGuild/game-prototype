require 'csv'

require 'stats_from_data/challenge'
require 'stats_from_data/contribution'
require 'stats_from_data/estimation'
require 'stats_from_data/experience'
require 'stats_from_data/health'
require 'stats_from_data/hours'
# require 'stats_from_data/mastery'
require 'stats_from_data/review'
require 'stats_from_data/support'

require 'utils'

class StatsFromData
  class << self
    def types
      @types ||= {}
    end
  end

  include Challenge
  include Contribution
  include Estimation
  include Experience
  include Health
  include Hours
  # include Mastery
  include Review
  include Support

  include Aggregates

  CYCLE_INCLUSION_LIMIT = 5 # how many previous cycles (beyond the current one) to use when weighting stats

  NO_DATA = 'MISSING DATA'

  attr_reader :data, :debug

  def initialize(game_data, opts = {})
    @data = game_data
    @debug = opts.fetch(:debug) { false }
  end

  # Helper queries

  def players(opts = {})
    data.cycle(opts[:cycle_no])
        .project(opts[:proj_name])
        .get_players(opts[:player_id])
  end

  def projects(opts = {})
    data.cycle(opts[:cycle_no])
        .get_projects(opts[:player_id])

  end

  def team(opts = {})
    raise "No team name specified" unless opts[:proj_name]

    data.get_team(opts[:proj_name])
  end

  def project_cycle_no(proj_name)
    proj = data.get_projects.find { |proj| proj[:name] == proj_name }
    proj[:cycle_no]
  end

  def cycles
    data.cycles.map(&:to_i).sort
  end

  def current_cycle
    cycles.last
  end

  def weighted_records(records, cycle_no)
    cycle_end = cycle_no || current_cycle
    cycle_begin = cycle_end > CYCLE_INCLUSION_LIMIT ? cycle_end - CYCLE_INCLUSION_LIMIT : 1

    records.cycle(cycle_begin..cycle_end)
  end

  def log(message)
    return nil unless debug

    case message
    when String
      puts message
    when Array
      puts message.map { |col| col.to_s.ljust(100 / message.count) }.join('| ')
    end
  end
end
