class StatReporter
  attr_reader :stats

  def initialize(stats)
    @stats = stats
  end

  def export
    report = stats.report

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
  puts r.export
end
