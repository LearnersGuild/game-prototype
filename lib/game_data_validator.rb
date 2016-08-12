class GameDataValidator
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def validate_hours_are_numeric
    invalid_hours = 0

    data.proj_hours.each do |record|
      begin
        hours = Float(record['value'])
      rescue ArgumentError
        invalid_hours += 1

        warn ""
        warn "[ERROR] Non-numeric hours: '#{record['value']}'"
        warn "  Record: #{record}"
        warn ""
      end
    end

    puts "Validated hours. #{invalid_hours} invalid record(s) found."
    invalid_hours.zero?
  end
end

if $PROGRAM_NAME == __FILE__
  require_relative './game_data.rb'

  gv = GameDataValidator.new(GameData.import(ARGV))
  gv.validate_hours_are_numeric
end
