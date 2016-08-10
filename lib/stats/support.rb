require 'stats/stat_type'

class Stats
  module Support
    extend StatType

    def culture_contribution(opts = {})
      scores = data.culture_contribution
                   .subject(opts[:player_id])
                   .cycle(opts[:cycle_no])
                   .values(&:to_i)

      mean(scores).to_percent(7)
    end

    def learning_support(opts = {})
      scores = data.learning_support
                   .subject(opts[:player_id])
                   .cycle(opts[:cycle_no])
                   .values(&:to_i)

      mean(scores).to_percent(7)
    end
  end
end
