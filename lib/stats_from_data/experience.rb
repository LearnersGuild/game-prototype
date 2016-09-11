require 'stats_from_data/stat_type'

class StatsFromData
  module Experience
    extend StatType

    def xp(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

      proj_xps = projects.map do |proj|
        next if opts[:proj_name] && proj[:name] != opts[:proj_name]

        proj[:completeness] = proj_completeness(proj_name: proj[:name])
        proj[:quality] = proj_quality(proj_name: proj[:name])
        proj[:total_hours] = proj_hours(proj_name: proj[:name])
        proj[:contribution] = actual_contribution(opts.merge(proj_name: proj[:name]))

        proj_xp = proj[:total_hours] \
                * (proj[:contribution] / 100.0) \
                * (proj[:completeness] / 100.0) \
                * (proj[:quality] / 100.0)

        proj_xp.round(2)
      end.reject(&:nil?)

      if proj_xps.empty?
        warn "Can't calculate XP for player #{opts[:player_id]}"
        return 0
      end

      proj_xps.reduce(:+).round(2)
    end
  end
end
