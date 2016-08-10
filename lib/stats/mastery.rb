require 'stats/stat_type'

class Stats
  module Mastery
    extend StatType

    def elo(opts = {})
    end

    def proj_effectiveness(opts = {})
      contribution = actual_contribution(opts)
      hours = proj_hours(opts)

      (contribution / hours.to_f).round(2)
    end
  end
end
