require 'stats/stat_type'

class Stats
  module Experience
    extend StatType

    def xp(opts = {})
      projects = data.cycle(opts[:cycle_no]).get_projects(opts[:player_id])

      proj_xps = projects.map do |proj_name, p_data|
        next if opts[:proj_name] && proj_name != opts[:proj_name]

        p_data[:completeness] = proj_completeness(proj_name: proj_name)
        p_data[:quality] = proj_quality(proj_name: proj_name)
        p_data[:total_hours] = proj_hours(proj_name: proj_name)
        p_data[:contribution] = actual_contribution(opts.merge(proj_name: proj_name))

        proj_xp = p_data[:total_hours] \
                * (p_data[:contribution] / 100.0) \
                * (p_data[:completeness] / 100.0) \
                * (p_data[:quality] / 100.0)

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
