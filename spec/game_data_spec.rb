require 'rspec'

require_relative "../game_data"

CLEAN_DATA = File.expand_path("../data/cycle-cleaned.csv", __FILE__)

describe GameData do
  let(:gd) { GameData.import([CLEAN_DATA]) }

  describe "#get_players" do
    describe "with no arguments" do
      it "returns all the players that have responses in the cycle data" do
        expect(gd.get_players.count).to eq(19)
      end
    end

    describe "when given a player id" do
      let(:player_id) { '75dbe257' } # player: 'jrob8577'

      it "returns data for the player" do
        expect(gd.get_players(player_id).first[:handle]).to eq('jrob8577')
      end
    end
  end
end
