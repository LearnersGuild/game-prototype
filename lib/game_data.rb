require 'csv'

class GameData
  class NoDataFileProvidedError < StandardError; end
  class MissingDataError < StandardError; end
  class InvalidCSVError < StandardError; end

  include Enumerable

  FIELDS = %w[ cycleNumber
               question
               questionId
               respondentEmail
               respondentHandle
               respondentId
               respondentName
               subject
               subjectId
               surveyId
               value ]

  QUESTION_TYPES = {
    contribution: 'cacefe2b-9193-41e1-9886-a0dd61fe9159',
    culture_contribution: '60fb5922-6be7-4e76-aaa3-16d574489833',
    text_feedback: 'cd350a14-8a70-4593-9801-30cedab3dc75',
    proj_hours: '29a4bc7e-631e-409b-a8ed-6d06a9ae39f7',
    learning_support: '26ccd2a0-64af-4bf4-ae6b-e87445a2b213',
    proj_completeness: '65cad3c5-e9e9-4284-999b-3a72c481c55e',
    proj_quality: '2c335ce5-ed0b-4068-92c8-56666fb7fdad',
    team_play: '57bc052d-1a7e-4faa-9617-11a93619ff6e',
    health_culture: '4b3b9383-b107-4e16-995e-4617d8f9e0f9',
    health_team_play: 'bb2927c9-a16d-49e9-8c3a-dd308a17315a',
    health_technical: '16d10fb3-463e-4d0a-b621-1557d9cfbeb9',
    zpd: '09dff295-c339-4326-8e21-71cf332e0895'
  }

  attr_reader :data

  def initialize(dataset=[])
    @data = dataset
  end

  def each(&block)
    data.each { |r| block.call(r) }
  end

  def self.import(files)
    raise NoDataFileProvidedError unless files.count > 0

    dataset = files.map do |file|
      csv = CSV.read(file, "r:ISO-8859-1", headers: true)
      raise InvalidCSVError unless csv.headers.sort == FIELDS.sort
      csv.map(&:to_hash)
    end.flatten

    self.new(dataset)
  end

  # create a query method for each of the above question types
  QUESTION_TYPES.each do |type, id|
    define_method(type) { self.class.new(data.select { |r| shortened(r['questionId']) == shortened(id) }) }
  end

  def cycle(cycle_no_or_range=nil)
    return self if cycle_no_or_range.nil?

    cycles = (Range === cycle_no_or_range) ? cycle_no_or_range : (cycle_no_or_range..cycle_no_or_range)

    self.class.new(data.select { |r| cycles.member?(r['cycleNumber'].to_i) })
  end

  def reporter_id(player_id=nil, opts={})
    return self if player_id.nil?
    if opts[:inverse]
      self.class.new(data.reject { |r| shortened(r['respondentId']) == shortened(player_id) })
    else
      self.class.new(data.select { |r| shortened(r['respondentId']) == shortened(player_id) })
    end
  end

  def subject(subject=nil, opts={})
    return self if subject.nil?
    if opts[:inverse]
      self.class.new(data.reject { |r| r['subject'] == subject })
    else
      self.class.new(data.select { |r| r['subject'] == subject })
    end
  end

  def subject_id(subj_id=nil, opts={})
    return self if subj_id.nil?
    if opts[:inverse]
      self.class.new(data.reject { |r| shortened(r['subjectId']) == shortened(subj_id) })
    else
      self.class.new(data.select { |r| shortened(r['subjectId']) == shortened(subj_id) })
    end
  end

  def survey(survey_id=nil, opts={})
    return self if survey_id.nil?
    if opts[:inverse]
      self.class.new(data.reject { |r| shortened(r['surveyId']) == shortened(survey_id) })
    else
      self.class.new(data.select { |r| shortened(r['surveyId']) == shortened(survey_id) })
    end
  end

  def get_project(proj_name=nil)
    return self if proj_name.nil?
    project = get_projects.find { |proj| proj[:name] == proj_name }
  end

  def project(proj_name=nil)
    return self if proj_name.nil?
    project = get_projects.find { |proj| proj[:name] == proj_name }

    subset = data.select do |r|
      shortened(r['surveyId']) == shortened(project[:survey]) \
        || shortened(r['subjectId']) == shortened(project[:subj])
    end
    self.class.new(subset)
  end

  def self_reported_contribution(player_id, proj_name)
    result = project(proj_name)
               .reporter_id(player_id)
               .subject_id(player_id)
               .contribution

    raise MissingDataError, "No self-reported contribution for player #{player_id} in project #{proj_name}" if result.none?
    result
  end

  def team_reported_contribution(player_id, proj_name)
    result = project(proj_name)
               .reporter_id(player_id, inverse: true)
               .subject_id(player_id)
               .contribution

    raise MissingDataError, "No team-reported contributions for player #{player_id} in project #{proj_name}" if result.none?

    result
  end

  def values
    data.map do |r|
      if block_given?
        yield r['value']
      else
        r['value']
      end
    end
  end

  def get_projects(player_id=nil)
    contributions = subject_id(player_id).contribution

    survey_ids = contributions.map { |r| r['surveyId'] }.uniq
    project_records = survey_ids.map { |survey_id| survey(survey_id).proj_hours.data }.flatten

    project_records.map { |r| { name: r['subject'], survey: r['surveyId'], subj: r['subjectId'], cycle_no: r['cycleNumber'] } }
                   .uniq
  end

  def get_players(player_id=nil)
    players = extract_player_info(data)
    return players.select { |player| shortened(player[:id]) == shortened(player_id) } if player_id
    players
  end

  def get_team(proj_name)
    extract_player_info(subject(proj_name).proj_hours)
  end

  def cycles
    data.map { |r| r['cycleNumber'] }.uniq
  end

  def team_size(proj_name)
    project(proj_name).proj_hours.count
  end

  def count
    data.count
  end

  def +(game_data)
    self.class.new(self.data + game_data.data)
  end

  def shortened(id)
    id.split('-').first
  end

  def extract_player_info(records)
    records.map do |r|
      {
        email: r['respondentEmail'],
        handle: r['respondentHandle'],
        id: shortened(r['respondentId']),
        name: r['respondentName']
      }
    end.uniq do |player|
      player[:id]
    end
  end

  def review_data
    completeness_data = proj_completeness.map do |record|
      { cycle_no: record['cycleNumber'].to_i,
        player_id: shortened(record['respondentId']),
        proj_name: record['subject'],
        review_type: 'proj_completeness',
        review_value: record['value'].to_f }
    end

    quality_data = proj_quality.map do |record|
      { cycle_no: record['cycleNumber'].to_i,
        player_id: shortened(record['respondentId']),
        proj_name: record['subject'],
        review_type: 'proj_quality',
        review_value: record['value'].to_f }
    end

    (completeness_data + quality_data).sort_by { |r| r[:cycle_no] }
  end
end
