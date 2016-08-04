require 'rspec'

require_relative "../stats"

TEST_DATA_CSV = File.expand_path("../data/cycle.csv", __FILE__)

describe Stats do
  let(:s) { Stats.new(TEST_DATA_CSV) }

  describe ".culture_contrib" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '070b3063', cycle_no: 3 } } # player: 'bluemihai'

      it "calculates culture contribution" do
        expect(s.culture_contrib(opts)).to eq(94.29)
      end
    end
  end
end
