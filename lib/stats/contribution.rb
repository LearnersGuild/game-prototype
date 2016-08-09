class Stats
  module Contribution
    def actual_contribution(opts = {})
      scores = data.project(opts[:proj_name])
                   .contribution
                   .subject(opts[:player_id])
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

    alias_method :contribution, :actual_contribution
    alias_method :project_contribution, :actual_contribution

    def expected_contribution(opts = {})
      (1 / data.team_size(opts[:proj_name]).to_f).to_percent(1)
    end

    def contribution_gap(opts = {})
      (contribution(opts) - expected_contribution(opts)).round(2)
    end
  end
end
