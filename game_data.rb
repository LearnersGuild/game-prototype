require 'csv'

class NoDataFileProvidedError < StandardError; end
class MissingDataError < StandardError; end

class GameData
  include Enumerable

  QUESTION_TYPES = {
    contribution: 'cacefe2b-9193-41e1-9886-a0dd61fe9159',
    culture_contrib: '60fb5922-6be7-4e76-aaa3-16d574489833',
    text_feedback: 'cd350a14-8a70-4593-9801-30cedab3dc75',
    proj_hours: '29a4bc7e-631e-409b-a8ed-6d06a9ae39f7',
    learning_support: '26ccd2a0-64af-4bf4-ae6b-e87445a2b213',
    proj_completeness: '65cad3c5-e9e9-4284-999b-3a72c481c55e',
    proj_quality: '2c335ce5-ed0b-4068-92c8-56666fb7fdad'
  }

  attr_reader :data

  def initialize(dataset)
    @data = dataset
  end

  def each(&block)
    data.each { |r| block.call(r) }
  end

  def self.import(files)
    raise NoDataFileProvidedError unless files.count > 0

    dataset = files.map do |file|
      csv = CSV.read(file, headers: true)
      csv.map(&:to_hash)
    end.flatten

    self.new(dataset)
  end

  # create a query method for each of the above question types
  QUESTION_TYPES.each do |type, id|
    define_method(type) { self.class.new(data.select { |r| shortened(r['questionId']) == shortened(id) }) }
  end

  def cycle(cycle_no=nil)
    return self if cycle_no.nil?
    self.class.new(data.select { |r| r['cycleNumber'].to_i == cycle_no.to_i })
  end

  def reporter(player_id=nil)
    return self if player_id.nil?
    if player_id[0] == '!' # use inverse
      self.class.new(data.reject { |r| shortened(r['respondentId']) == shortened(player_id) })
    else
      self.class.new(data.select { |r| shortened(r['respondentId']) == shortened(player_id) })
    end
  end

  def subject(subj_id=nil)
    return self if subj_id.nil?
    if subj_id[0] == '!' # use inverse
      self.class.new(data.reject { |r| shortened(r['subjectId']) == shortened(subj_id) })
    else
      self.class.new(data.select { |r| shortened(r['subjectId']) == shortened(subj_id) })
    end
  end

  def project(proj_name=nil)
    return self if proj_name.nil?
    project = projects[proj_name]

    subset = data.select do |r|
      shortened(r['surveyId']) == shortened(project[:survey]) \
        || shortened(r['subjectId']) == shortened(project[:subj])
    end
    self.class.new(subset)
  end

  def self_reported_contribution(player_id, proj_name)
    result = project(proj_name)
               .reporter(player_id)
               .subject(player_id)
               .contribution

    raise MissingDataError, "No self-reported contribution for player #{player_id} in project #{proj_name}" if result.none?
    result
  end

  def team_reported_contribution(player_id, proj_name)
    result = project(proj_name)
               .reporter('!' + player_id)
               .subject(player_id)
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

  def projects(player_id=nil)
    project_hours = reporter(player_id).proj_hours
    raise MissingDataError, "No project hours reported by player with id #{player_id}" if project_hours.none?

    Hash[
      project_hours.map { |r| [ r['subject'], { survey: r['surveyId'], subj: r['subjectId'] } ] }
                   .uniq
    ]
  end

  def players
    data.map do |entry|
      {
        email: entry['respondentEmail'],
        handle: entry['respondentHandle'],
        id: entry['respondentId'],
        name: entry['respondentName']
      }
    end.uniq do |player|
      player[:id]
    end
  end

  def team_size(proj_name)
    project(proj_name).proj_hours.count
  end

  def count
    data.count
  end

  def shortened(id)
    id.split('-').first
  end

end

if $PROGRAM_NAME == __FILE__
  require 'pry'

  gd = GameData.import(ARGV)
  binding.pry
end
