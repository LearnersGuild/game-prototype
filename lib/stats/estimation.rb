require 'stats/stat_type'

class Stats
  module Estimation
    extend StatType

    def contribution_accuracy(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

      accuracies = projects.map do |proj_name, p_data|
        next if opts[:proj_name] && proj_name != opts[:proj_name]

        p_data[:self_rep_contrib] = self_reported_contribution(opts.merge(proj_name: proj_name))
        p_data[:team_rep_contrib] = team_reported_contribution(opts.merge(proj_name: proj_name))

        if p_data[:self_rep_contrib].nil?
          warn "Can't calculate contribution_accuracy for player #{opts[:player_id]} in project #{proj_name}"
          next
        end

        p_data[:self_rep_contrib] - p_data[:team_rep_contrib]
      end

      accuracies = accuracies.reject(&:nil?)
      accuracies = accuracies.map(&:abs) unless opts[:include_negatives]

      return 'missing data' if accuracies.none?
      mean(accuracies).round(2)
    end

    def contribution_bias(opts = {})
      contribution_accuracy(opts.merge(include_negatives: true))
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
  end
end
