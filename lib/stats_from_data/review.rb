require 'stats_from_data/stat_type'

class StatsFromData
  module Review
    extend StatType

    def review_data
      data.review_data
    end

    def proj_completeness(opts = {})
      scores = data.project(opts[:proj_name])
                   .proj_completeness
                   .values(&:to_i)

      mean(scores).to_percent(100)
    end

    def proj_completeness_for_player(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])
      scores = projects.map { |proj| proj_completeness(proj_name: proj[:name]) }

      return NO_DATA if scores.none?
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
      scores = projects.map { |proj| proj_quality(proj_name: proj[:name]) }

      return NO_DATA if scores.none?
      mean(scores).to_percent(100)
    end

    def no_proj_reviews(opts = {})
      projects_with_completeness = data.cycle(opts[:cycle_no])
                                       .reporter_id(opts[:player_id])
                                       .proj_completeness
                                       .map { |r| r['subjectId'] }
                                       .uniq

      projects_with_completeness.reduce(0) do |count, subj_id|
        has_quality_review = data.cycle(opts[:cycle_no])
                                 .reporter_id(opts[:player_id])
                                 .subject_id(subj_id)
                                 .proj_quality
                                 .any?

        count += 1 if has_quality_review
        count
      end
    end
  end
end
