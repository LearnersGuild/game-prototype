require 'stats/stat_type'

class Stats
  module Hours
    extend StatType

    def proj_hours(opts = {})
      hours = data.project(opts[:proj_name])
                  .cycle(opts[:cycle_no])
                  .reporter_id(opts[:player_id])
                  .proj_hours
                  .values

      hours.map(&:to_f).reduce(:+)
    end

    def avg_cycle_hours(opts = {})
      hours = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).proj_hours
      hours_per_cycle = hours.reduce([]) do |cycles, r|
        cycle_no = r['cycleNumber'].to_i - 1
        cycles[cycle_no] ||= []
        cycles[cycle_no] << r['value'].to_i
        cycles
      end.reject(&:nil?).map { |hours| hours.reduce(:+) }

      mean(hours_per_cycle).round(2)
    end
  end
end
