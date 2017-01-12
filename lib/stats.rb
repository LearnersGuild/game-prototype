require 'csv'

require 'mastery'
require 'cycle_hours'
require 'utils'

class Stats
  include Aggregates
  include Mastery
  include CycleHours

  NO_OF_PREV_ACTIVE_UNIQUE_REVIEWERS = 12 # for health evaluations
  NO_OF_PREV_ACTIVE_CYCLES = 6 # for weighting
  NO_DATA = 'MISSING DATA'

  attr_reader :proj_stats, :review_stats, :game_data

  def initialize(proj_stats, review_stats, game_data = nil)
    @proj_stats = proj_stats
    @review_stats = review_stats
    @game_data = game_data
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

  def time_on_task(id)
    all_hours = project_hours_per_cycle(id)

    hour_ratio = all_hours.map do |cycle_no, hours|
      no_projects = hours.count
      hours_per_project = hours_for_cycle(cycle_no) / no_projects

      percents_on_task = hours.map do |hour|
        hour > hours_per_project ? 1 : hour / hours_per_project
      end

      [cycle_no, mean(percents_on_task).round(2)]
    end

    weighted_ratios = hour_ratio.sort_by { |cycle_hours| -cycle_hours[0] }
                                .take(NO_OF_PREV_ACTIVE_CYCLES)

    mean(weighted_ratios.map { |_, ratio| ratio }).to_percent(100)
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

  def health_culture(id)
    stats = weighted_stats(id).map { |s| s['health_culture'] }
                              .reject { |n| n.nil? || n == NO_DATA }
                              .map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def health_adjusted_culture(id)

    # Get last 8 project stats
    unique_culture_feedbacks = unique_feedback(game_data.health_culture, id)

    return NO_DATA if unique_culture_feedbacks.none?

    stats = unique_culture_feedbacks.map do |culture_feedback|

      respondentId = game_data.shortened(culture_feedback["respondentId"])
      puts "respondentId #{respondentId}"
      value = culture_feedback["value"].to_f
      puts "value #{value}"
      max_average = retro_average(respondentId, "retro_max_culture")
      puts "max aveage #{max_average}"
      min_average = retro_average(respondentId, "retro_min_culture")
      puts "min average #{min_average}"
      stat = (value - min_average) / (max_average - min_average)
      puts "stat #{stat}"
      stat
    end


    stats
  end

  def health_team_play(id)
    stats = weighted_stats(id).map { |s| s['health_team_play'] }
                              .reject { |n| n.nil? || n == NO_DATA }
                              .map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def health_technical(id)
    stats = weighted_stats(id).map { |s| s['health_technical'] }
                              .reject { |n| n.nil? || n == NO_DATA }
                              .map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats).to_percent(100)
  end

  def retro_average(id,stat)
    rmcs = proj_stats.for_player(id).map { |s| s[stat].to_f }
    rmcs.reduce(:+) / rmcs.size.to_f
  end


  def challenge(id)
    stats = weighted_stats(id).map { |s| s['challenge'] }
    stats = stats.reject { |n| n.nil? || n == NO_DATA }
    stats = stats.map(&:to_f)

    return NO_DATA if stats.none?
    mean(stats)
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

  def current_cycle
    proj_stats.map { |s| s['cycle_no'].to_i }.max
  end

  def project_hours_per_cycle(id)
    hours = proj_stats.for_player(id).map { |s| [s['cycle_no'].to_i, s['proj_hours'].to_f] }

    hours.reduce({}) do |cycles, hours|
      cycle_no, proj_hours = hours
      cycles[cycle_no] ||= []
      cycles[cycle_no] << proj_hours
      cycles
    end
  end

private

  def weighted_stats(id)
    proj_stats.for_player(id)
              .group_by { |s| s['cycle_no'].to_i }
              .sort
              .reverse
              .take(NO_OF_PREV_ACTIVE_CYCLES)
              .map { |_, projs| projs }
              .flatten
  end

  def unique_feedback(feedback_collection, id)
    feedback_collection.select {|hc| game_data.shortened(hc["subjectId"]) == id }
                            .sort{|n,m| m["cycleNumber"].to_f <=> n["cycleNumber"].to_f}
                            .uniq{|a| a["respondentId"]}
                            .first(NO_OF_PREV_ACTIVE_UNIQUE_REVIEWERS)
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
