require 'stats/stat_type'
require 'utils'

class Stats
  module Mastery
    extend StatType

    def elo(opts = {})
    end

    def proj_effectiveness(opts = {})
      contribution = actual_contribution(opts)
      hours = proj_hours(opts)

      (contribution / hours.to_f).round(2)
    end

  private

    # scoreboard is a data structure storing player Elo rankings
    # it has the following shape:
    # { 'player_id' => { elo: Elo::Player, handle: '@handle', name: 'name' }
    def _scoreboard
      return @scoreboard if @scoreboard
      @scoreboard = Hash[
        players.map { |player| [player[:id], _new_player(player)] }
      ]
    end

    def _new_player(player)
      if PROFESSIONAL_PLAYERS.include?(player[:id])
        initial_rating = PROFESSIONAL_INITIAL_RATING
      else
        initial_rating = DEFAULT_INITIAL_RATING
      end

      player.merge(elo: Elo::Player.new(rating: initial_rating))
    end

    def _generate_rankings(opts = {})
      return @generated if @generated

      cycle_limit = opts[:cycle_no] || cycles.last

      1.upto(cycle_limit) do |cycle_no|
        report " --- "
        report "Running games for cycle #{cycle_no}..."

        cycle_projects = projects(cycle_no: cycle_no).sort_by { |proj| proj[:name] }

        cycle_projects.each do |proj|
          team = teams(proj_name: proj[:name]).map { |player| _scoreboard[player[:id]] }
          handles = team.map { |p| p[:handle] }

          report " --- "
          report "Running games for project #{proj[:name]}..."
          report "Team: #{handles.join(', ')}"

          team.combination(2).each do |player_a, player_b|
            _play(player_a, player_b)
          end
        end
      end

      @generated = true
    end

    def _play(player_a, player_b)
      report " ~ "
      report "Match: #{player_a[:handle]}(#{player_a[:elo].rating}) vs. #{player_b[:handle]}(#{player_b[:elo].rating})"

      game = player_a[:elo].versus(player_b[:elo])
      game.result = _game_result(player_a, player_b)

      report [ "game outcome", player_a[:handle], player_b[:handle] ]
      report [ game.result.round(2), player_a[:elo].rating, player_b[:elo].rating ]
    end

    def _game_result(player_a, player_b)
      a_effectiveness = proj_effectiveness(player_id: player_a[:id])
      b_effectiveness = proj_effectiveness(player_id: player_b[:id])

      # margin-based ELO
      return a_effectiveness / (a_effectiveness + b_effectiveness).to_f

      # return 0.5 if (((a_effectiveness-b_effectiveness).abs/a_effectiveness) < 0.1)
      # return 1 if a_effectiveness > b_effectiveness
      # return 0 if b_effectiveness > a_effectiveness
    end
  end
end
