require 'stats_from_data/stat_type'
require 'cycle_hours'

class StatsFromData
  module Hours
    extend StatType
    include CycleHours

    def proj_hours(opts = {})
      hours = data.project(opts[:proj_name])
                  .cycle(opts[:cycle_no])
                  .reporter_id(opts[:player_id])
                  .proj_hours
                  .values

      hours.map(&:to_f).reduce(:+)
    end

    def time_on_task(opts = {})
      all_hours = project_hours_per_cycle(opts)

      task_hours = all_hours.map do |cycle_no, hours|
        no_projects = hours.count
        hours_per_project = hours_for_cycle(cycle_no) / no_projects

        hours_on_task = hours.map do |hour|
          hour > hours_per_project ? 1 : hour / hours_per_project
        end

        [cycle_no, mean(hours_on_task).round(2)]
      end

      Hash[task_hours]
    end

    def avg_cycle_hours(opts = {})
      all_hours = project_hours_per_cycle(opts).map do |cycle, hours|
        next unless cycle && !hours.empty?
        hours.reduce(:+)
      end

      mean(all_hours).round(2)
    end

    def project_hours_per_cycle(opts = {})
      hours = data.cycle(opts[:cycle_no]).reporter_id(opts[:player_id]).proj_hours
      hours.reduce({}) do |cycles, r|
        cycle_no = r['cycleNumber'].to_i
        cycles[cycle_no] ||= []
        cycles[cycle_no] << r['value'].to_f
        cycles
      end
    end
  end
end
