class StatReporter
  attr_reader :stats

  def initialize(stats)
    @stats = stats
  end

  def stat_names
    stats.stat_names
  end

  def full_report(as=:csv)
    report = stats.report

    return csv(report) if as == :csv
    report
  end

  def player_report(player_id, as=:csv)
    report = []
    report << player_aggreagate_report(player_id)

    stats.cycles.sort.each do |cycle_no|
      report << player_cycle_report(player_id: player_id, cycle_no: cycle_no)

      projects = stats.projects(player_id: player_id, cycle_no: cycle_no)
      projects.sort.each do |proj_name, p_data|
        report << player_project_report(player_id: player_id, proj_name: proj_name)
      end
    end

    return csv(report) if as == :csv
    report
  end

  def player_aggreagate_report(player_id)
    aggregate_report = stats.report(player_id: player_id).first
    aggregate_report.delete(:name)
    aggregate_report.delete(:handle)
    { period: 'aggregated stats' }.merge(aggregate_report)
  end

  def player_cycle_report(opts = {})
    cycle_report = {
      period: "cycle #{opts[:cycle_no]}",
      xp: stats.xp(opts),
      avg_proj_comp: stats.proj_completeness_for_player(opts),
      avg_proj_qual: stats.proj_quality_for_player(opts),
      lrn_supp: stats.learning_support(opts),
      cult_cont: stats.culture_contrib(opts),
      discern: stats.discernment(opts),
      no_proj_rvws: stats.no_proj_reviews(opts)
    }
  end

  def player_project_report(opts = {})
    proj_report = {
      period: "project #{opts[:proj_name]}",
      xp: stats.xp(opts),
      avg_proj_comp: stats.proj_completeness_for_player(opts),
      avg_proj_qual: stats.proj_quality_for_player(opts),
      lrn_supp: stats.learning_support(opts),
      cult_cont: stats.culture_contrib(opts),
      discern: stats.discernment(opts),
    }
  end

  def csv(report)
    CSV.generate do |csv|
      headers = report.first.keys
      csv << headers

      report.each do |player_stats|
        csv << headers.map { |h| player_stats[h] }
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require_relative './stats.rb'

  s = Stats.new(*ARGV)
  r = StatReporter.new(s)
  binding.pry
end
