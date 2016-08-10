require 'csv'

require 'stats/accuracy'
require 'stats/contribution'
require 'stats/experience'
require 'stats/hours'
require 'stats/review'
require 'stats/support'

require 'stats/utils'

class Stats
  include Accuracy
  include Contribution
  include Experience
  include Hours
  include Review
  include Support

  include Aggregates

  TYPES = %i[ xp avg_cycle_hours avg_proj_comp avg_proj_qual lrn_supp cult_cont contrib_accuracy contrib_bias no_proj_rvws ]

  attr_reader :data

  def initialize(game_data)
    @data = game_data
  end

  # Helper queries

  def players(opts = {})
    data.cycle(opts[:cycle_no])
        .get_players(opts[:player_id])
  end

  def projects(opts = {})
    data.cycle(opts[:cycle_no])
        .get_projects(opts[:player_id])
  end

  def cycles
    data.cycles
  end
end
