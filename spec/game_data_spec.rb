require_relative './spec_config'

require 'game_data'

describe GameData do
  let(:gd) { GameData.import([CLEAN_DATA]) }
  let(:prof_player_id) { '75dbe257' } # player: 'jrob8577'

  describe "#get_players" do
    describe "with no arguments" do
      it "returns all the players that have responses in the cycle data" do
        expect(gd.get_players.count).to eq(19)
      end
    end

    describe "when given a player id" do
      it "returns data for the player" do
        expect(gd.get_players(prof_player_id).first[:handle]).to eq('jrob8577')
      end
    end
  end

  describe "using inverse: true" do
    it "provides inverted results for certain methods" do
      others_hours = gd.reporter_id(prof_player_id, inverse: true).proj_hours
      reporters = others_hours.map { |r| r['respondentId'] }

      expect(reporters).not_to include(prof_player_id)
    end
  end

  describe "#get_team" do
    it "returns all players who worked together on a specific project" do
      team_players = gd.get_team('wiggly-jacana').map { |p| p[:id] }
      expect(team_players).to include('75dbe257', '936e3168', 'cbcff678')
    end
  end
end
