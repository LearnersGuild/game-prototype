require_relative './spec_config'

require 'stat_reporter'
require 'game_data'

describe StatReporter do
  let(:s) { Stats.new( GameData.import([CLEAN_DATA]) ) }
  let(:sr) { StatReporter.new( s ) }

  describe "#report" do
    let(:rep) { sr.report }

    it "is anonymous by default" do
      expect(rep.first.keys).not_to include(:name, :handle, :email)
    end

    describe "when given a player id" do
      it "calculates the correct stats for the player" do
        player_stats = sr.report(player_id: '75dbe257') # player: 'jrob8577'

        expected_stats = [{ id: '75dbe257',
                            xp: 100.56,
                            avg_cycle_hours: 40.0,
                            avg_proj_comp: 87.94,
                            avg_proj_qual: 83.52,
                            lrn_supp: 94.29,
                            cult_cont: 97.14,
                            contrib_accuracy: 9.17,
                            contrib_bias: 9.17,
                            no_proj_rvws: 7 }]

        expect(player_stats).to eq(expected_stats)
      end
    end

    describe "when the :anonymous flag is set to false" do
      it "will show player name and handle" do
        report = sr.report(player_id: '75dbe257', anonymous: false)

        expect(report.first.keys).to include(:name, :handle)
      end
    end
  end
end
