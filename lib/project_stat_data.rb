require 'csv'

class ProjectStatData
  class NoDataFileProvidedError < StandardError; end
  class MissingDataError < StandardError; end
  class InvalidCSVError < StandardError; end

  include Enumerable

  FIELDS = %w[ cycle_no
               project
               id
               xp
               proj_hours
               avg_proj_comp
               avg_proj_qual
               lrn_supp
               cult_cont
               team_play
               project_contrib
               expected_contrib
               contrib_gap
               est_accuracy
               est_bias ]

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
      csv = CSV.read(file, headers: true)
      raise InvalidCSVError unless csv.headers.sort == FIELDS.sort
      csv.map(&:to_hash)
    end.flatten

    self.new(dataset)
  end
end
