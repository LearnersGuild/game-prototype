require 'csv'

class NoDataFileProvidedError < StandardError; end

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

  def shortened(id)
    id.split('-').first
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

  # create a query method for each of the above question types
  QUESTION_TYPES.each do |type, id|
    define_method(type) { self.class.new(data.select { |r| shortened(r['questionId']) == shortened(id) }) }
  end

  def cycle(cycle_no)
    self.class.new(data.select { |r| r['cycleNumber'].to_i == cycle_no.to_i })
  end

  def giver(player_id)
    self.class.new(data.select { |r| shortened(r['respondentId']) == shortened(player_id) })
  end

  def receiver(player_id)
    self.class.new(data.select { |r| shortened(r['subjectId']) == shortened(player_id) })
  end

  def project(proj_name)
    project = projects[proj_name]

    subset = data.select do |r|
      shortened(r['surveyId']) == shortened(project[:survey]) \
        || shortened(r['subjectId']) == shortened(project[:subj])
    end
    self.class.new(subset)
  end

  def projects
    @projects ||= Hash[
      proj_hours.map { |r| [ r['subject'], { survey: r['surveyId'], subj: r['subjectId'] } ] }.uniq
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
end

if $PROGRAM_NAME == __FILE__
  require 'pry'

  gd = GameData.import(ARGV)
  binding.pry
end