require 'stats/stat_type'

class Stats
  module Estimation
    extend StatType

    def estimation_accuracy(opts = {})
      100 - _estimation_differences(opts)
    end

    def estimation_bias(opts = {})
      _estimation_differences(opts.merge(include_negatives: true))
    end

    def self_reported_contribution(opts = {})
      begin
        data.self_reported_contribution(opts[:player_id], opts[:proj_name])
            .values(&:to_i)
            .first
            .to_percent(100)
      rescue GameData::MissingDataError => e
        warn "No self-reported contribution for #{opts}"
        nil
      end
    end

    def team_reported_contribution(opts = {})
      scores = data.team_reported_contribution(opts[:player_id], opts[:proj_name])
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

  private

    def _estimation_differences(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

      accuracies = projects.map do |proj|
        next if opts[:proj_name] && proj[:name] != opts[:proj_name]

        self_rep_contrib = self_reported_contribution(opts.merge(proj_name: proj[:name]))
        team_rep_contrib = team_reported_contribution(opts.merge(proj_name: proj[:name]))

        if self_rep_contrib.nil?
          warn "Can't calculate _estimation_differences for player #{opts[:player_id]} in project #{proj[:name]}"
          next
        end

        self_rep_contrib - team_rep_contrib
      end

      accuracies = accuracies.reject(&:nil?)
      accuracies = accuracies.map(&:abs) unless opts[:include_negatives]

      return 'missing data' if accuracies.none?
      mean(accuracies).round(2)
    end
  end
end
