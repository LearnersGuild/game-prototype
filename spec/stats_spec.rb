require 'rspec'

require_relative "../stats"

RAW_DATA = File.expand_path("../data/cycle-raw.csv", __FILE__)
CLEAN_DATA = File.expand_path("../data/cycle-cleaned.csv", __FILE__)

describe Stats do
  let(:s) { Stats.new(CLEAN_DATA) }
  let(:s_raw) { Stats.new(RAW_DATA) }

  describe "#report" do
    it "builds a report with all players stats" do
      headers = [ :name, :handle, :xp, :avg_proj_comp, :avg_proj_qual, :lrn_supp, :cult_cont, :discern, :no_proj_rvws ]

      expect(s.report.count).to eq(19)
      expect(s.report.first.keys.sort).to eq(headers.sort)
    end

    it "calculates the correct stats for the player" do
      player_stats = s.report.find { |s| s[:handle] == 'jrob8577' }

      expected_stats = { name: 'John Roberts',
                         handle: 'jrob8577',
                         xp: 100.56,
                         avg_proj_comp: 87.94,
                         avg_proj_qual: 83.52,
                         lrn_supp: 94.29,
                         cult_cont: 97.14,
                         discern: 6.05,
                         no_proj_rvws: 7 }

      expect(player_stats).to eq(expected_stats)
    end
  end

  describe "#xp" do
    describe "when given a player" do
      let(:opts) { { player_id: '75dbe257' } } # player: 'jrob8577'

      it "calculates XP for the player across all cycles and projects" do
        expect(s.xp(opts)).to eq(100.56)
      end
    end

    describe "when given a player and a project" do
      let(:opts) { { player_id: '75dbe257', proj_name: 'wiggly-jacana' } } # player: 'jrob8577'

      it "calculates XP for the player in the particular project" do
        expect(s.xp(opts)).to eq(37.18)
      end
    end
  end

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

  describe "#discernment" do
    describe "when given a player id" do
      let(:opts) { { player_id: 'adda47cf' } } # player: 'harmanisdeep'

      it "determines how accurate their judgment is relative to others'" do
        expect(s.discernment(opts)).to eq(1.67)
      end

      it "is always expressed as a positive number" do
        opts = { player_id: 'cbcff678' } # player: 'Moniarchy'
        expect(s.discernment(opts)).to be > 0
      end

      it "even works with advanced players" do
        opts[:player_id] = '75dbe257' # player: 'jrob8577'
        expect(s.discernment(opts)).to eq(6.05)
      end
    end

    describe "when given a player id and a project name" do
      let(:opts) { { player_id: '75dbe257', proj_name: 'cluttered-partridge' } } # player: 'jrob8577'

      it "limits the discernment score to just the project scores" do
        one_project_score = s.discernment(opts)

        expect(one_project_score).to eq(13.33)
        expect(s.discernment(player_id: opts[:player_id])).not_to eq(one_project_score)
      end
    end
  end

  describe "#contribution_dissonance" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates the difference between actual contribution and expected contribution" do
        expect(s.contribution_dissonance(opts)).to eq(28.33 - (1 / 3.0).round(2))
      end
    end
  end

  describe "#expected_contribution" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates how much contribution is expected of a player based on team size" do
        expect(s.expected_contribution(opts)).to eq((1 / 3.0).round(2))
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
        expect { s_raw.proj_hours(opts) }.to raise_error(InvalidHoursValueError)
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
