require_relative './spec_config'

require 'stats'
require 'game_data'

describe Stats do
  let(:s) { Stats.new( GameData.import([CLEAN_DATA]) ) }
  let(:s_raw) { Stats.new( GameData.import([RAW_DATA]) ) }

  let(:opts_adv_player) { { player_id: '75dbe257' } } # player: 'jrob8577'
  let(:opts_adv_player_project) { { player_id: '75dbe257', proj_name: 'wiggly-jacana' } }
  let(:opts_player) { { player_id: 'adda47cf' } } # player: 'harmanisdeep'
  let(:opts_proj) { { proj_name: 'cluttered-partridge' } }
  let(:opts_player_proj) { { player_id: 'adda47cf', proj_name: 'cluttered-partridge' } }
  let(:opts_underestimated_player) { { player_id: 'cbcff678' } } # player: 'Moniarchy'

  describe "#xp" do
    describe "when given a player" do
      it "calculates XP for the player across all cycles and projects" do
        expect(s.xp(opts_adv_player)).to eq(100.56)
      end
    end

    describe "when given a player and a project" do
      it "calculates XP for the player in the particular project" do
        expect(s.xp(opts_adv_player_project)).to eq(37.18)
      end
    end
  end

  describe "#elo" do
    describe "when given a player" do
      it "calculates the correct Elo ranking for that player" do
        expect(s.elo(opts_adv_player)).to eq(1372)
      end
    end

    xit "is not a deterministic number, because it randomizes project and player order" do

    end
  end

  describe "#proj_effectiveness" do
    describe "when given a player and a project" do
      it "determines the potency/effectiveness of a player's time" do
        expect(s.proj_effectiveness(opts_adv_player_project)).to eq(3.48)
      end
    end
  end

  describe "#culture_contribution" do
    describe "when given a player" do
      it "calculates mean culture contribution as a 2-decimal percentage" do
        expect(s.culture_contribution(opts_adv_player)).to eq(97.14)
      end
    end
  end

  describe "#learning_support" do
    describe "when given a player" do
      it "calculates mean learning support as 2-decimal percentage" do
        expect(s.learning_support(opts_adv_player)).to eq(94.29)
      end
    end
  end

  describe "#proj_completeness" do
    describe "when given a project name" do
      it "calculates project completeness as 2-decimal percentage" do
        expect(s.proj_completeness(opts_proj)).to eq(86.83)
      end
    end
  end

  describe "#proj_quality" do
    describe "when given a project name" do
      it "calculates mean project quality as 2-decimal percentage" do
        expect(s.proj_quality(opts_proj)).to eq(85.06)
      end
    end
  end

  describe "#actual_contribution" do
    describe "when given a player id and a project name" do
      it "calculates mean contribution percentage as a 2-decimal percentage" do
        expect(s.actual_contribution(opts_player_proj)).to eq(28.33)
      end

      it "even works with advanced players" do
        expect(s.actual_contribution(opts_adv_player_project)).to eq(55.67)
      end
    end
  end

  describe "#expected_contribution" do
    describe "when given a player id and a project name" do
      it "calculates how much contribution is expected of a player based on team size" do
        expect(s.expected_contribution(opts_player_proj)).to eq(33.33)
      end
    end
  end

  describe "#contribution_gap" do
    describe "when given a player id and a project name" do
      it "calculates the difference between actual contribution and expected contribution" do
        expect(s.contribution_gap(opts_player_proj)).to eq(28.33 - 33.33)
      end
    end
  end

  describe "#contribution_accuracy" do
    describe "when given a player id" do
      it "determines how accurate their judgment is relative to others'" do
        expect(s.contribution_accuracy(opts_player)).to eq(2.5)
      end

      it "is always expressed as a positive number" do
        expect(s.contribution_accuracy(opts_underestimated_player)).to be > 0
      end

      it "even works with advanced players" do
        expect(s.contribution_accuracy(opts_adv_player)).to eq(9.17)
      end
    end

    describe "when given a player id and a project name" do
      it "limits the contribution_accuracy score to just the project scores" do
        one_project_score = s.contribution_accuracy(opts_adv_player_project)
        overall_score = s.contribution_accuracy(player_id: opts_adv_player_project[:player_id])

        expect(one_project_score).to eq(6.5)
        expect(overall_score).not_to eq(one_project_score)
      end
    end
  end

  describe "#contribution_bias" do
    it "calculates average +/-% a player's self-evaluation is relative to their peer's evalution of them" do
      expect(s.contribution_bias(opts_underestimated_player)).to eq(-10.0)
    end
  end

  describe "#proj_hours" do
    describe "when given a player id and a project name" do
      it "finds the hours worked by the player on that project" do
        expect(s.proj_hours(opts_adv_player_project)).to eq(16)
      end
    end
  end

  describe "#avg_cycle_hours" do
    it "calculates the mean hours worked per cycle" do
      expect(s.avg_cycle_hours(opts_adv_player)).to eq(40)
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
