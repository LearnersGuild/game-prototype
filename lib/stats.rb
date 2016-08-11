require 'csv'

require 'stats/contribution'
require 'stats/estimation'
require 'stats/experience'
require 'stats/hours'
require 'stats/mastery'
require 'stats/review'
require 'stats/support'

require 'stats/utils'

class Stats
  class << self
    def types
      @types ||= {}
    end
  end

  include Contribution
  include Estimation
  include Experience
  include Hours
  include Mastery
  include Review
  include Support

  include Aggregates

  attr_reader :data, :verbose

  def initialize(game_data, opts = {})
    @data = game_data
    @verbose = opts.fetch(:verbose) { false }
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

  def cycles
    data.cycles.map(&:to_i).sort
  end

  def report(message)
    return nil unless verbose

    case message
    when String
      puts message
    when Array
      puts message.map { |col| col.to_s.ljust(80 / message.count) }.join('| ')
    end
  end
end
