class StatReporter
  attr_reader :stats, :anonymous

  def initialize(stats, anonymous=true)
    @stats = stats
    @anonymous = anonymous
  end

  def report(opts = {})
    stats.player_ids.map do |id|
      stat_report = {}

      stat_report[:id] = id
      stat_report[:xp] = stats.xp(id)
      stat_report[:avg_cycle_hours] = stats.avg_cycle_hours(id)
      stat_report[:avg_proj_comp] = stats.proj_completeness_for_player(id)
      stat_report[:avg_proj_qual] = stats.proj_quality_for_player(id)
      stat_report[:lrn_supp] = stats.learning_support(id)
      stat_report[:cult_cont] = stats.culture_contribution(id)
      stat_report[:team_play] = stats.team_play(id)
      stat_report[:est_accuracy] = stats.estimation_accuracy(id)
      stat_report[:est_bias] = stats.estimation_bias(id)
      stat_report[:no_proj_rvws] = stats.no_proj_reviews(id)
      stat_report[:elo] = stats.elo(id)

      stat_report
    end
  end

  def full_report(as=:csv)
    report = report(anonymous: anonymous)

    return csv(report) if as == :csv
    report
  end

  def project_report(proj_name, as=:csv)
    report = []

    player_ids = stats.team(proj_name: proj_name).map { |p| p[:id] }
    player_ids.each do |p_id|
      report << player_project_report(proj_name: proj_name, player_id: p_id)
    end

    return csv(report) if as == :csv
    report
  end

  def review_report(as=:csv)
    report = stats.review_data

    return csv(report) if as == :csv
    report
  end

  def player_report(player_id, as=:csv)
    report = []
    report << player_aggreagate_report(player_id)

    stats.cycles.sort.each do |cycle_no|
      report << player_cycle_report(player_id: player_id, cycle_no: cycle_no)

      projects = stats.projects(player_id: player_id, cycle_no: cycle_no)
      projects.sort_by { |p| p[:name] }.each do |proj|
        report << player_project_report(player_id: player_id, proj_name: proj[:name])
      end
    end

    return csv(report) if as == :csv
    report
  end

  def player_aggreagate_report(player_id)
    aggregate_report = report(player_id: player_id, anonymous: anonymous).first
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
      cult_cont: stats.culture_contribution(opts),
      team_play: stats.team_play(opts),
      est_accuracy: stats.estimation_accuracy(opts),
      est_bias: stats.estimation_bias(opts),
      no_proj_rvws: stats.no_proj_reviews(opts)
    }
  end

  def player_project_report(opts = {})
    proj_report = {
      cycle_no: stats.project_cycle_no(opts[:proj_name]),
      project: opts[:proj_name],
      id: opts[:player_id],
      xp: stats.xp(opts),
      proj_hours: stats.proj_hours(opts),
      avg_proj_comp: stats.proj_completeness_for_player(opts),
      avg_proj_qual: stats.proj_quality_for_player(opts),
      lrn_supp: stats.learning_support(opts),
      cult_cont: stats.culture_contribution(opts),
      team_play: stats.team_play(opts),
      project_contrib: stats.actual_contribution(opts),
      expected_contrib: stats.expected_contribution(opts),
      contrib_gap: stats.contribution_gap(opts),
      est_accuracy: stats.estimation_accuracy(opts),
      est_bias: stats.estimation_bias(opts),
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
