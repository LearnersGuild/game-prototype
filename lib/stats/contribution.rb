require 'stats/stat_type'

class Stats
  module Contribution
    extend StatType

    def actual_contribution(opts = {})
      scores = data.project(opts[:proj_name])
                   .contribution
                   .subject(opts[:player_id])
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

    def expected_contribution(opts = {})
      player_hours = proj_hours(player_id: opts[:player_id], proj_name: opts[:proj_name])
      proj_hours = proj_hours(proj_name: opts[:proj_name])

      (player_hours / proj_hours.to_f).to_percent(1)
    end

    def contribution_gap(opts = {})
      (actual_contribution(opts) - expected_contribution(opts)).round(2)
    end
  end
end
