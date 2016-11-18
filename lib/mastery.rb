require 'elo'

Elo.configure do |config|
  config.default_k_factor = 20
  config.use_FIDE_settings = false
end

CSV_LOG_HEADERS = [ :cycle_no, :project, :a, :a_start_elo, :a_effect, :a_end_elo, :b, :b_start_elo, :b_effect, :b_end_elo, :game_outcome ]

def csv_log(vals)
  puts CSV_LOG_HEADERS.map { |k| vals[k] }.join(',') if ENV['DEBUG']
end

$log_message = {}

class Stats
  module Mastery
    # [ jrob jared mihai sj tanner deonna ]
    PROFESSIONAL_PLAYERS = %w[ 75dbe257 dcf14075 070b3063 3760fbe8 f490c8ee ed958f6f ]
    PROFESSIONAL_INITIAL_RATING = 0
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

      puts CSV_LOG_HEADERS.map(&:to_s).join(',') if ENV['DEBUG']

      1.upto(current_cycle) do |cycle_no|
        cycle_projects = projects(cycle_no).sort

        $log_message[:cycle_no] = cycle_no

        cycle_projects.each do |proj_name|
          team = team(proj_name)
          team = team - PROFESSIONAL_PLAYERS # don't play PROFESSIONAL_PLAYERS
          team_players = team.map { |player_id| _scoreboard[player_id] }

          $log_message[:project] = proj_name

          team_players.combination(2).each do |players|
            _play(players, proj_name)
          end
        end
      end

      @generated = true
    end

    def _play(players, proj_name)
      $log_message[:a] = players[0][:id]
      $log_message[:a_start_elo] = players[0][:elo].rating
      $log_message[:b] = players[1][:id]
      $log_message[:b_start_elo] = players[1][:elo].rating

      game = players[0][:elo].versus(players[1][:elo])

      begin
        game.result = _game_result(players, proj_name)
      rescue RuntimeError
        warn "Can't calculate elo for:"
        warn players, proj_name
        exit
      end

      game_outcome = game.result.round(2)
      $log_message[:a_end_elo] = players[0][:elo].rating
      $log_message[:b_end_elo] = players[1][:elo].rating

      csv_log($log_message)

      return game_outcome
    end

    def _game_result(players, proj_name)
      effectivenesses = players.map { |player| proj_effectiveness(player[:id], proj_name) }
      $log_message[:a_effect] = effectivenesses[0]
      $log_message[:b_effect] = effectivenesses[1]

      # margin-based ELO
      result = effectivenesses[0] / (effectivenesses[0] + effectivenesses[1]).to_f
      $log_message[:game_outcome] = result

      scaled_outcome = _scale_game_result(result)
      return scaled_outcome
    end

    STRETCH_FACTOR = 3

    def _scale_game_result(result)
      new_result = ((result - 0.5) * STRETCH_FACTOR) + 0.5
      new_result = 1 if new_result > 1
      new_result = 0 if new_result < 0
      return new_result
    end
  end
end
