require 'stats/stat_type'

class Stats
  module Review
    extend StatType

    def proj_completeness(opts = {})
      scores = data.project(opts[:proj_name])
                   .proj_completeness
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

    def proj_completeness_for_player(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])
      scores = projects.map { |proj_name, _| proj_completeness(proj_name: proj_name) }

      return 'missing data' if scores.none?
      mean(scores).to_percent(100)
    end

    def proj_quality(opts = {})
      scores = data.project(opts[:proj_name])
                   .proj_quality
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

    def proj_quality_for_player(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])
      scores = projects.map { |proj_name, _| proj_quality(proj_name: proj_name) }

      return 'missing data' if scores.none?
      mean(scores).to_percent(100)
    end

    def no_proj_reviews(opts = {})
      data.cycle(opts[:cycle_no])
          .reporter(opts[:player_id])
          .proj_completeness
          .count
    end
  end
end
