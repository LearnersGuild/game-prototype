require 'rspec'

require_relative "../stats"

TEST_DATA_CSV = File.expand_path("../data/cycle.csv", __FILE__)

describe Stats do
  let(:s) { Stats.new(TEST_DATA_CSV) }

  describe "#culture_contrib" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '75dbe257', cycle_no: 3 } } # player: 'jrob8577'

      it "calculates culture contribution as a 2-decimal percentage" do
        expect(s.culture_contrib(opts)).to eq(97.14)
      end
    end
  end

  describe "#learning_support" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '75dbe257', cycle_no: 3 } } # player: 'jrob8577'

      it "calculates learning support as 2-decimal percentage" do
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

      it "calculates project quality as 2-decimal percentage" do
        expect(s.proj_quality(opts)).to eq(85.06)
      end
    end
  end
end
