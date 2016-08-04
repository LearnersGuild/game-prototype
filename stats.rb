require 'csv'

# headers:
# cycleNumber,question,questionId,respondentEmail,respondentHandle,respondentId,respondentName,subject,subjectId,surveyId,value

QUESTION_ID = {
  contribution: 'cacefe2b-9193-41e1-9886-a0dd61fe9159',
  culture_contrib: '60fb5922-6be7-4e76-aaa3-16d574489833',
  text_feedback: 'cd350a14-8a70-4593-9801-30cedab3dc75',
  project_hours: '29a4bc7e-631e-409b-a8ed-6d06a9ae39f7',
  learning_support: '26ccd2a0-64af-4bf4-ae6b-e87445a2b213',
  proj_completeness: '65cad3c5-e9e9-4284-999b-3a72c481c55e',
  proj_quality: '2c335ce5-ed0b-4068-92c8-56666fb7fdad'
}

def question_id(question_type)
  QUESTION_ID[question_type].split('-')[0]
end

class Numeric
  def to_percent(limit, decimal = 2)
    ((self / limit.to_f) * 100).round(decimal)
  end
end

class InvalidHoursValueError < StandardError; end

class Stats
  attr_reader :files

  def initialize(file)
    @file = file
    @csv = CSV.read(@file, headers: true)
  end

  def culture_contrib(opts = {})
    question_id = question_id(:culture_contrib)
    player_id = opts.fetch(:player_id)
    cycle = opts.fetch(:cycle_no)

    scores = @csv.select do |entry|
      entry['subjectId'] == player_id \
        && entry['questionId'] == question_id \
        && entry['cycleNumber'].to_i == cycle.to_i
    end.map do |entry|
      entry['value'].to_i
    end

    score = scores.reduce(:+) / scores.count.to_f

    score.to_percent(7)
  end

  def learning_support(opts = {})
    question_id = question_id(:learning_support)
    player_id = opts.fetch(:player_id)
    cycle = opts.fetch(:cycle_no)

    scores = @csv.select do |entry|
      entry['subjectId'] == player_id \
        && entry['questionId'] == question_id \
        && entry['cycleNumber'].to_i == cycle.to_i
    end.map do |entry|
      entry['value'].to_i
    end

    score = scores.reduce(:+) / scores.count.to_f

    score.to_percent(7)
  end

  def proj_completeness(opts = {})
    proj_name = opts.fetch(:proj_name)
    question_id = question_id(:proj_completeness)

    scores = @csv.select do |entry|
      entry['subject'] == proj_name \
        && entry['questionId'] == question_id
    end.map do |entry|
      entry['value'].to_i
    end

    score = scores.reduce(:+) / scores.count.to_f

    score.to_percent(100)
  end

  def proj_quality(opts = {})
    proj_name = opts.fetch(:proj_name)
    question_id = question_id(:proj_quality)

    scores = @csv.select do |entry|
      entry['subject'] == proj_name \
        && entry['questionId'] == question_id
    end.map do |entry|
      entry['value'].to_i
    end

    score = scores.reduce(:+) / scores.count.to_f

    score.to_percent(100)
  end

  def contribution(opts = {})
    player_id = opts.fetch(:player_id)
    proj_name = opts.fetch(:proj_name)
    proj_survey_id = project_ids[proj_name]
    question_id = question_id(:contribution)

    scores = @csv.select do |entry|
      entry['subjectId'] == player_id \
        && entry['surveyId'] == proj_survey_id \
        && entry['questionId'] == question_id
    end.map do |entry|
      entry['value'].to_i
    end

    score = scores.reduce(:+) / scores.count.to_f

    score.to_percent(100)
  end

  def project_hours(opts = {})
    player_id = opts.fetch(:player_id)
    proj_name = opts.fetch(:proj_name)
    proj_survey_id = project_ids[proj_name]
    question_id = question_id(:project_hours)

    hoursResponse = @csv.find do |entry|
      entry['respondentId'] == player_id \
        && entry['surveyId'] == proj_survey_id \
        && entry['questionId'] == question_id
    end

    hours = hoursResponse['value']

    unless hours =~ /\A\d+\z/ # must be nothing but numbers
      raise InvalidHoursValueError, "Can't parse '#{hours}'"
    end
    
    hours.to_i
  end

  def project_ids(opts = {})
    cycle_no = opts.fetch(:cycle_no, nil)
    question_id = question_id(:project_hours)

    project_ids = @csv.select do |entry|
      (cycle_no.nil? || entry['cycleNumber'].to_i == cycle_no) \
        && entry['questionId'] == question_id
    end.map do |entry|
      [entry['subject'], entry['surveyId']]
    end.uniq

    Hash[project_ids]
  end
end

if $PROGRAM_NAME == __FILE__
  s = Stats.new(ARGV[0])
  # p s.culture_contrib(player_id: '070b3063', cycle_no: 3)
  p s.project_ids
end
