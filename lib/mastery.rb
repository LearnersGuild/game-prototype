require 'elo'

Elo.configure do |config|
  config.k_factor(100) { games_played < 20 }
  config.default_k_factor = 20
  config.use_FIDE_settings = false
end

class Stats
  module Mastery
    PROFESSIONAL_PLAYERS = %w[ 75dbe257 dcf14075 070b3063 ]# %w[ jrob8577 deadlyicon bluemihai ]
    PROFESSIONAL_INITIAL_RATING = 1300
    DEFAULT_INITIAL_RATING = 1000

    def elo(player_id)
      _generate_rankings
      _scoreboard[player_id][:elo].rating
    end

    def proj_effectiveness(player_id, proj_name)
      contribution = actual_contribution(proj_name, player_id)
      hours = proj_hours(proj_name, player_id)

      (contribution / hours.to_f).round(2)
    end

  private

    # scoreboard is a data structure storing player Elo rankings
    # it has the following shape:
    # { 'player_id' => { elo: Elo::Player, id: 'player_id' }
    def _scoreboard
      return @scoreboard if @scoreboard
      @scoreboard = Hash[
        player_ids.map { |id| [id, _enable_elo(id)] }
      ]
    end

    def _enable_elo(id)
      if PROFESSIONAL_PLAYERS.include?(id)
        initial_rating = PROFESSIONAL_INITIAL_RATING
      else
        initial_rating = DEFAULT_INITIAL_RATING
      end

      { id: id, elo: Elo::Player.new(rating: initial_rating) }
    end

    def _generate_rankings
      return @generated if @generated

      1.upto(current_cycle) do |cycle_no|
        log " --- "
        log "Running games for cycle #{cycle_no}..."

        cycle_projects = projects(cycle_no).sort

        cycle_projects.each do |proj_name|
          team = team(proj_name).map { |player_id| _scoreboard[player_id] }
          # handles = team.map { |p| p[:handle] }

          log " --- "
          log "Running games for project #{proj_name}..."
          # log "Team: #{handles.join(', ')}"

          team.combination(2).each do |players|
            _play(players, proj_name)
          end
        end
      end

      @generated = true
    end

    def _play(players, proj_name)
      before_a = "#{players[0][:id]}(#{players[0][:elo].rating})"
      before_b = "#{players[1][:id]}(#{players[1][:elo].rating})"

      game = players[0][:elo].versus(players[1][:elo])
      game.result = _game_result(players, proj_name)

      game_outcome = game.result.round(2)
      after_a = "#{players[0][:id]}(#{players[0][:elo].rating})"
      after_b = "#{players[1][:id]}(#{players[1][:elo].rating})"
      log [ before_a, before_b, game_outcome, after_a, after_b ]
    end

    def _game_result(players, proj_name)
      effectivenesses = players.map { |player| proj_effectiveness(player[:id], proj_name) }

      # margin-based ELO
      return effectivenesses[0] / (effectivenesses[0] + effectivenesses[1]).to_f

      # return 0.5 if (((effectivenesses[0]-effectivenesses[1]).abs/effectivenesses[0]) < 0.1)
      # return 1 if effectivenesses[0] > effectivenesses[1]
      # return 0 if effectivenesses[1] > effectivenesses[0]
    end
  end
end
