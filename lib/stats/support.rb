require 'stats/stat_type'

class Stats
  module Support
    extend StatType

    def culture_contribution(opts = {})
      scores = _zero_based_scores(data.culture_contribution, opts)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def learning_support(opts = {})
      scores = _zero_based_scores(data.learning_support, opts)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def team_play(opts = {})
      scores = _zero_based_scores(data.team_play, opts)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

  private

    # Use 0..6 Likert scale (input values are 0..7, with 0 = N/A)
    def _zero_based_scores(records, opts)
      records.subject_id(opts[:player_id])
             .cycle(opts[:cycle_no])
             .values(&:to_i)
             .map { |v| (v - 1) }
    end

    # Don't use N/A values when calculating stats
    def _filter_out_not_applicables(scores)
      scores.reject { |v| v == -1 }
    end
  end
end
