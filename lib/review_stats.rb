require 'csv'

class ReviewStats
  class NoDataFileProvidedError < StandardError; end
  class MissingDataError < StandardError; end
  class InvalidCSVError < StandardError; end

  include Enumerable

  FIELDS = %w[ cycle_no
               player_id
               proj_name
               review_type
               review_value ]

  attr_reader :data

  def initialize(dataset=[])
    @data = dataset
  end

  def each(&block)
    data.each { |r| block.call(r) }
  end

  def for_player(id)
    data.select { |s| s['player_id'] == id }
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
