class StatReporter
  attr_reader :stats, :anonymous

  def initialize(stats, anonymous=true)
    @stats = stats
    @anonymous = anonymous
  end

  def full_report(as=:csv)
    report = stats.report(anonymous: anonymous)

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
    aggregate_report = stats.report(player_id: player_id, anonymous: anonymous).first
    { period: 'aggregated stats' }.merge(aggregate_report)
  end

  def player_cycle_report(opts = {})
    cycle_report = {
      period: "cycle #{opts[:cycle_no]}",
      id: opts[:player_id],
      xp: stats.xp(opts),
      proj_hours: stats.proj_hours(opts),
      avg_proj_comp: stats.proj_completeness_for_player(opts),
      avg_proj_qual: stats.proj_quality_for_player(opts),
      lrn_supp: stats.learning_support(opts),
      cult_cont: stats.culture_contrib(opts),
      contrib_accuracy: stats.contribution_accuracy(opts),
      contrib_bias: stats.contribution_bias(opts),
      no_proj_rvws: stats.no_proj_reviews(opts)
    }
  end

  def player_project_report(opts = {})
    proj_report = {
      period: "project #{opts[:proj_name]}",
      id: opts[:player_id],
      xp: stats.xp(opts),
      proj_hours: stats.proj_hours(opts),
      avg_proj_comp: stats.proj_completeness_for_player(opts),
      avg_proj_qual: stats.proj_quality_for_player(opts),
      lrn_supp: stats.learning_support(opts),
      cult_cont: stats.culture_contrib(opts),
      project_contrib: stats.project_contribution(opts),
      expected_contrib: stats.expected_contribution(opts),
      contrib_gap: stats.contribution_gap(opts),
      contrib_accuracy: stats.contribution_accuracy(opts),
      contrib_bias: stats.contribution_bias(opts),
    }
  end

  def csv(report)
    CSV.generate do |csv|
      headers = report.map(&:keys).flatten.uniq
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
