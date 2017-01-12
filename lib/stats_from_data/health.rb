require 'stats_from_data/stat_type'

class StatsFromData
  module Health
    extend StatType

    def health_culture(opts = {})
      records = data.cycle(opts[:cycle_no]).subject_id(opts[:player_id]).health_culture
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def health_team_play(opts = {})
      records = data.cycle(opts[:cycle_no]).subject_id(opts[:player_id]).health_team_play
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def health_technical(opts = {})
      records = data.cycle(opts[:cycle_no]).subject_id(opts[:player_id]).health_technical
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      mean(scores).to_percent(6)
    end

    def retro_max_culture(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_culture
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.max
    end

    def retro_min_culture(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_culture
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.min
    end

    def retro_max_team_play(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_team_play
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.max
    end

    def retro_min_team_play(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_team_play
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.min
    end

    def retro_max_technical(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_technical
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.max
    end

    def retro_min_technical(opts = {})
      records = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).health_technical
      scores = _zero_based_scores(records)
      scores = _filter_out_not_applicables(scores)

      return NO_DATA if scores.none?
      scores.min
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
