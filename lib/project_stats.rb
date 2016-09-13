require 'csv'

class ProjectStats
  class NoDataFileProvidedError < StandardError; end
  class MissingDataError < StandardError; end
  class InvalidCSVError < StandardError; end

  include Enumerable

  FIELDS = %w[ cycle_no
               project
               id
               xp
               proj_hours
               proj_comp
               proj_qual
               lrn_supp
               cult_cont
               team_play
               project_contrib
               expected_contrib
               contrib_gap
               est_accuracy
               est_bias ]

  attr_reader :data

  def initialize(dataset, cycle_limit)
    @data = dataset.select { |s| s['cycle_no'].to_i <= cycle_limit }
  end

  def each(&block)
    data.each { |r| block.call(r) }
  end

  def for_player(id)
    data.select { |s| s['id'] == id }
  end

  def self.import(files, cycle_limit)
    raise NoDataFileProvidedError unless files.count > 0

    dataset = files.map do |file|
      csv = CSV.read(file, headers: true)
      raise InvalidCSVError unless csv.headers.sort == FIELDS.sort
      csv.map(&:to_hash)
    end.flatten

    self.new(dataset, cycle_limit)
  end
end
