class GameDataValidator
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def run
    validate_hours_are_numeric
    check_project_reviews
    check_all_team_members_have_hours
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

  def check_all_team_members_have_hours
    teams_missing_hours = []

    data.get_projects.each do |project|
      team_ids = data.survey(project[:survey]).contribution.map { |r| r['subjectId'] }.uniq
      hours_ids = data.subject_id(project[:subj]).proj_hours.map { |r| r['respondentId'] }.uniq

      missing_hours = team_ids - hours_ids
      if missing_hours.any?
        missing = { project: project[:name], cycle: project[:cycle_no], players: missing_hours }
        teams_missing_hours << missing
        warn "[MISSING DATA] No hours reported for full team of: '#{project[:name]}'"
        warn "  Cycle: #{missing[:cycle]} IDs: #{missing[:players]}"
      end
    end

    puts "Checked project hours. #{teams_missing_hours.count} projects are missing hours."
    teams_missing_hours.none?
  end
end
