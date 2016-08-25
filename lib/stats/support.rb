require 'stats/stat_type'

class Stats
  module Support
    extend StatType

    def culture_contribution(opts = {})
      records = data.subject_id(opts[:player_id]).culture_contribution
      records = weighted_records(records, opts[:cycle_no])
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def learning_support(opts = {})
      records = data.subject_id(opts[:player_id]).learning_support
      records = weighted_records(records, opts[:cycle_no])
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def team_play(opts = {})
      records = data.subject_id(opts[:player_id]).team_play
      records = weighted_records(records, opts[:cycle_no])
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

  private

    # Use 0..6 Likert scale (input values are 0..7, with 0 = N/A)
    def _zero_based_scores(records)
      records.values.map { |v| (v.to_i - 1) }
    end

    # Don't use N/A values when calculating stats
    def _filter_out_not_applicables(scores)
      scores.reject { |v| v == -1 }
    end
  end
end
