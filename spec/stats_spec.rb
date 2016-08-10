require_relative './spec_config'

require 'stats'
require 'game_data'

describe Stats do
  let(:s) { Stats.new( GameData.import([CLEAN_DATA]) ) }
  let(:s_raw) { Stats.new( GameData.import([RAW_DATA]) ) }

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

  describe "#culture_contribution" do
    describe "when given a player and cycle" do
      let(:opts) { { player_id: '75dbe257', cycle_no: 3 } } # player: 'jrob8577'

      it "calculates mean culture contribution as a 2-decimal percentage" do
        expect(s.culture_contribution(opts)).to eq(97.14)
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

  describe "#actual_contribution" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates mean contribution percentage as a 2-decimal percentage" do
        expect(s.actual_contribution(opts)).to eq(28.33)
      end

      it "even works with advanced players" do
        opts[:player_id] = '75dbe257' # player: 'jrob8577'
        expect(s.actual_contribution(opts)).to eq(46.67)
      end
    end
  end

  describe "#expected_contribution" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates how much contribution is expected of a player based on team size" do
        expect(s.expected_contribution(opts)).to eq(33.33)
      end
    end
  end

  describe "#contribution_gap" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } } # player: 'harmanisdeep'

      it "calculates the difference between actual contribution and expected contribution" do
        expect(s.contribution_gap(opts)).to eq(28.33 - 33.33)
      end
    end
  end

  describe "#contribution_accuracy" do
    describe "when given a player id" do
      let(:opts) { { player_id: 'adda47cf' } } # player: 'harmanisdeep'

      it "determines how accurate their judgment is relative to others'" do
        expect(s.contribution_accuracy(opts)).to eq(2.5)
      end

      it "is always expressed as a positive number" do
        opts = { player_id: 'cbcff678' } # player: 'Moniarchy'
        expect(s.contribution_accuracy(opts)).to be > 0
      end

      it "even works with advanced players" do
        opts[:player_id] = '75dbe257' # player: 'jrob8577'
        expect(s.contribution_accuracy(opts)).to eq(9.17)
      end
    end

    describe "when given a player id and a project name" do
      let(:opts) { { player_id: '75dbe257', proj_name: 'cluttered-partridge' } } # player: 'jrob8577'

      it "limits the contribution_accuracy score to just the project scores" do
        one_project_score = s.contribution_accuracy(opts)

        expect(one_project_score).to eq(20.0)
        expect(s.contribution_accuracy(player_id: opts[:player_id])).not_to eq(one_project_score)
      end
    end
  end

  describe "#contribution_bias" do
    let(:opts) { { player_id: 'cbcff678' } } # player: 'Moniarchy'

    it "calculates average +/-% a player's self-evaluation is relative to their peer's evalution of them" do
      expect(s.contribution_bias(opts)).to eq(-10.0)
    end
  end

  describe "#proj_hours" do
    describe "when given a player id and a project name" do
      let(:opts) { { player_id: '75dbe257', proj_name: 'cluttered-partridge' } } # player: 'jrob8577'

      it "finds the hours worked by the player on that project" do
        expect(s.proj_hours(opts)).to eq(10)
      end
    end
  end

  describe "#avg_cycle_hours" do
    let(:opts) { { player_id: '75dbe257' } } # player: 'jrob8577'

    it "calculates the mean hours worked per cycle" do
      expect(s.avg_cycle_hours(opts)).to eq(40)
    end
  end

  describe ".types" do
    let(:types) { Stats.types }

    it "returns a mapping of all stat types and their stat methods" do
      expect(types.keys).to include(:estimation, :support)
      expect(types[:support]).to include(:culture_contribution, :learning_support)
    end

    it "returns callable methods of the same name" do
      types.values.flatten.each do |stat_method|
        expect(s).to respond_to(stat_method)
      end
    end
  end
end
