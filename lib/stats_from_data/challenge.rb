require 'stats_from_data/stat_type'

class StatsFromData
  module Challenge
    extend StatType

    def challenge(opts = {})
      zpds = data.project(opts[:proj_name])
                 .cycle(opts[:cycle_no])
                 .reporter_id(opts[:player_id])
                 .zpd
                 .values

      zpds.map(&:to_f).reduce(:+)
    end
  end
end
