class GameDataValidator
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def run
    validate_hours_are_numeric
    check_project_reviews
  end

  def validate_hours_are_numeric
    invalid_hours = 0

    data.proj_hours.each do |record|
      begin
        hours = Float(record['value'])
      rescue ArgumentError
        invalid_hours += 1

        warn "[ERROR] Non-numeric hours: '#{record['value']}'"
        warn "  Record: #{record}"
      end
    end

    puts "Validated hours. #{invalid_hours} invalid record(s) found."
    invalid_hours.zero?
  end

  def check_project_reviews
    projs_missing_reviews = []

    data.get_projects.each do |proj|
      no_completeness_reviews = data.subject(proj[:name]).proj_completeness.none?
      no_quality_reviews = data.subject(proj[:name]).proj_quality.none?

      if no_completeness_reviews && no_completeness_reviews
        projs_missing_reviews << proj
        warn "[MISSING DATA] No project reviews for proj: '#{proj[:name]}'"
        warn "  Project: #{proj}"
      end
    end

    puts "Checked project reviews. #{projs_missing_reviews.count} projects are missing reviews."
    projs_missing_reviews.none?
  end
end
