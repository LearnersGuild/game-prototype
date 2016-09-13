require 'csv'

require 'mastery'

require 'utils'

class Stats
  include Aggregates
  include Mastery

  CYCLE_INCLUSION_LIMIT = 5 # how many previous cycles (beyond the current one) to use when weighting stats

  NO_DATA = 'MISSING DATA'

  attr_reader :proj_stats, :review_stats

  def initialize(proj_stats, review_stats)
    @proj_stats = proj_stats
    @review_stats = review_stats
  end

  # proj stat queries

  def player_ids
    proj_stats.map { |s| s['id'] }.uniq
  end

  def projects(cycle_no)
    proj_stats.select { |s| s['cycle_no'].to_i == cycle_no }.map { |s| s['project'] }.uniq
  end

  def team(proj_name)
    proj_stats.select { |s| s['project'] == proj_name }.map { |s| s['id'] }
  end

  def actual_contribution(proj_name, player_id)
    proj_stats.for_player(player_id).find { |s| s['project'] == proj_name }['project_contrib'].to_f
  end

  def proj_hours(proj_name, player_id)
    proj_stats.for_player(player_id).find { |s| s['project'] == proj_name }['proj_hours'].to_f
  end

  # aggregate stats

  def xp(id)
    proj_xps = proj_stats.for_player(id).map { |s| s['xp'].to_f }
    proj_xps.reduce(:+).round(2)
  end

  def avg_cycle_hours(id)
    hours = proj_stats.for_player(id).map { |s| [s['cycle_no'].to_i, s['proj_hours'].to_f] }

    hours_per_cycle = hours.reduce([]) do |cycles, hours|
      cycle_no = hours[0] - 1
      cycles[cycle_no] ||= []
      cycles[cycle_no] << hours[1]
      cycles
    end.reject(&:nil?).map { |hours| hours.reduce(:+) }

    mean(hours_per_cycle).round(2)
  end

  def culture_contribution(id)
    stats = weighted_stats(id).map { |s| s['cult_cont'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def learning_support(id)
    stats = weighted_stats(id).map { |s| s['lrn_supp'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def team_play(id)
    stats = weighted_stats(id).map { |s| s['team_play'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def estimation_accuracy(id)
    stats = weighted_stats(id).map { |s| s['est_accuracy'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def estimation_bias(id)
    stats = weighted_stats(id).map { |s| s['est_bias'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def proj_completeness_for_player(id)
    stats = proj_stats.for_player(id).map { |s| s['proj_comp'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def proj_quality_for_player(id)
    stats = proj_stats.for_player(id).map { |s| s['proj_qual'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def no_proj_reviews(id)
    total_count = review_stats.for_player(id).count
    total_count -= 1 if total_count.odd?

    total_count / 2
  end

private

  def weighted_stats(id)
    cycle_end = current_cycle
    cycle_begin = cycle_end > CYCLE_INCLUSION_LIMIT ? cycle_end - CYCLE_INCLUSION_LIMIT : 1
    cycle_range = (cycle_begin..cycle_end)

    proj_stats.for_player(id).select { |s| cycle_range.include? s['cycle_no'].to_i }
  end

  def current_cycle
    proj_stats.map { |s| s['cycle_no'].to_i }.max
  end

  def log(message)
    return nil unless ENV['DEBUG']

    case message
    when String
      puts message
    when Array
      puts message.map { |col| col.to_s.ljust(100 / message.count) }.join('| ')
    end
  end
end
