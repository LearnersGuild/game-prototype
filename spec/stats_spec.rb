require 'rspec'

require_relative "../stats"

TEST_DATA_CSV = File.expand_path("../data/cycle.csv", __FILE__)

describe Stats do
  let(:s) { Stats.new(TEST_DATA_CSV) }

  describe "#culture_contrib" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '75dbe257', cycle_no: 3 } } # player: 'jrob8577'

      it "calculates mean culture contribution as a 2-decimal percentage" do
        expect(s.culture_contrib(opts)).to eq(97.14)
      end
    end
  end

  describe "#learning_support" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '75dbe257', cycle_no: 3 } } # player: 'jrob8577'

      it "calculates mean learning support as 2-decimal percentage" do
        expect(s.learning_support(opts)).to eq(94.29)
      end
    end
  end

  describe "#proj_completeness" do
    describe "when given a project name" do
      let(:opts) { { proj_name: 'cluttered-partridge' } }

      it "calculates project completeness as 2-decimal percentage" do
        expect(s.proj_completeness(opts)).to eq(86.83)
      end
    end
  end

  describe "#proj_quality" do
    describe "when given a project name" do
      let(:opts) { { proj_name: 'cluttered-partridge' } }

      it "calculates mean project quality as 2-decimal percentage" do
        expect(s.proj_quality(opts)).to eq(85.06)
      end
    end
  end

  describe "#contribution" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates mean contribution percentage as a 2-decimal percentage" do
        expect(s.contribution(opts)).to eq(28.33)
      end

      it "even works with advanced players" do
        opts[:player_id] = '75dbe257' # player: 'jrob8577'
        expect(s.contribution(opts)).to eq(46.67)
      end
    end
  end

  describe "#proj_hours" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: '75dbe257', proj_name: 'cluttered-partridge' } } # player: 'jrob8577'

      it "finds the hours worked by the player on that project" do
        expect(s.proj_hours(opts)).to eq(10)
      end
    end

    describe "when an unparseable answer arises" do
      let(:opts) { { player_id: '936e3168', proj_name: 'wiggly-jacana' } } # player: 'rachel-ftw'

      it "it throws an InvalidHoursValueError error" do
        expect { s.proj_hours(opts) }.to raise_error(InvalidHoursValueError)
      end
    end
  end

  describe "#players" do
    describe "with no arguments" do
      it "returns all the players that have responses in the cycle data" do
        expect(s.players.count).to eq(19)
      end
    end

    describe "when given a player id" do
      let(:opts) { { player_id: '75dbe257' } } # player: 'jrob8577'

      it "returns data for the player" do
        expect(s.players(opts)[:handle]).to eq('jrob8577')
      end
    end
  end
end
