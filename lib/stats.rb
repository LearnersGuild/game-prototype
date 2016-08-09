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

  def report(opts = {})
    default_opts = { player_id: nil, anonymous: true }
    opts = default_opts.merge(opts)

    data.get_players(opts[:player_id]).map do |player|
      id = player[:id]

      stat_report = {}

      unless opts[:anonymous]
        stat_report[:name] = player[:name]
        stat_report[:handle] = player[:handle]
      end

      stat_report[:id] = id
      stat_report[:xp] = xp(player_id: id)
      stat_report[:avg_cycle_hours] = avg_cycle_hours(player_id: id)
      stat_report[:avg_proj_comp] = proj_completeness_for_player(player_id: id)
      stat_report[:avg_proj_qual] = proj_quality_for_player(player_id: id)
      stat_report[:lrn_supp] = learning_support(player_id: id)
      stat_report[:cult_cont] = culture_contrib(player_id: id)
      stat_report[:contrib_accuracy] = contribution_accuracy(player_id: id)
      stat_report[:contrib_bias] = contribution_bias(player_id: id)
      stat_report[:no_proj_rvws] = no_proj_reviews(player_id: id)

      stat_report
    end
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
  require './game_data.rb'

  s = Stats.new(GameData.import(ARGV))
  binding.pry
end
