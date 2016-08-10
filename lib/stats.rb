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

  attr_reader :data

  def initialize(game_data)
    @data = game_data
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
end
