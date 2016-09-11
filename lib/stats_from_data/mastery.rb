require 'elo'
require 'stats_from_data/stat_type'

Elo.configure do |config|
  config.k_factor(100) { games_played < 20 }
  config.default_k_factor = 20
  config.use_FIDE_settings = false
end

class StatsFromData
  module Mastery
    PROFESSIONAL_PLAYERS = %w[ jrob8577 deadlyicon bluemihai ]
    PROFESSIONAL_INITIAL_RATING = 1300
    DEFAULT_INITIAL_RATING = 1000

    extend StatType

    def elo(opts = {})
      _generate_rankings
      _scoreboard[opts[:player_id]][:elo].rating
    end

    def proj_effectiveness(opts = {})
      raise "No project name provided" unless opts[:proj_name]
      raise "No player id provided" unless opts[:proj_name]

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
        players.map { |player| [player[:id], _enable_elo(player)] }
      ]
    end

    def _enable_elo(player)
      if PROFESSIONAL_PLAYERS.include?(player[:handle])
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
        log " --- "
        log "Running games for cycle #{cycle_no}..."

        cycle_projects = projects(cycle_no: cycle_no).sort_by { |proj| proj[:name] }

        cycle_projects.each do |proj|
          team = team(proj_name: proj[:name]).map { |player| _scoreboard[player[:id]] }
          handles = team.map { |p| p[:handle] }

          log " --- "
          log "Running games for project #{proj[:name]}..."
          log "Team: #{handles.join(', ')}"

          team.combination(2).each do |players|
            _play(players, proj)
          end
        end
      end

      @generated = true
    end

    def _play(players, proj)
      before_a = "#{players[0][:handle]}(#{players[0][:elo].rating})"
      before_b = "#{players[1][:handle]}(#{players[1][:elo].rating})"

      game = players[0][:elo].versus(players[1][:elo])
      game.result = _game_result(players, proj)

      game_outcome = game.result.round(2)
      after_a = "#{players[0][:handle]}(#{players[0][:elo].rating})"
      after_b = "#{players[1][:handle]}(#{players[1][:elo].rating})"
      log [ before_a, before_b, game_outcome, after_a, after_b ]
    end

    def _game_result(players, proj)
      effectivenesses = players.map { |player| proj_effectiveness(player_id: player[:id], proj_name: proj[:name]) }

      # margin-based ELO
      return effectivenesses[0] / (effectivenesses[0] + effectivenesses[1]).to_f

      # return 0.5 if (((effectivenesses[0]-effectivenesses[1]).abs/effectivenesses[0]) < 0.1)
      # return 1 if effectivenesses[0] > effectivenesses[1]
      # return 0 if effectivenesses[1] > effectivenesses[0]
    end
  end
end
