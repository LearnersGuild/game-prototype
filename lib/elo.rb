require 'csv'
require 'elo'

Elo.configure do |config|
  config.k_factor(200) { games_played < 20 }
  config.default_k_factor = 16
  config.use_FIDE_settings = false
end


@teams = CSV.read(File.expand_path("../../teams2.csv", __FILE__), headers:true)

@players = Hash[@teams.map{|x| [x["player"], Elo::Player.new]}]

@players["Jared Grippe"] = Elo::Player.new(:rating => 1400)
@players["John Roberts"] = Elo::Player.new(:rating => 1400)
@players["Mihai Banulescu"] = Elo::Player.new(:rating => 1400)

puts @players.inspect

def game_result(p1_index, p2_index)
  p1_score = @teams[p1_index]["contriboverhours"].to_f
  p2_score = @teams[p2_index]["contriboverhours"].to_f

  return p1_score/(p1_score + p2_score) # margin-based ELO

  return 0.5 if (((p1_score-p2_score).abs/p1_score) < 0.1)
  return 1 if p1_score > p2_score
  return 0 if p2_score > p1_score
end

def play(p1_index, p2_index)
  p1 = @teams[p1_index]["player"]
  p2 = @teams[p2_index]["player"]
  output = "|#{p1}(#{@players[p1].rating}) \t| #{p2}(#{@players[p2].rating})"
  game = @players[p1].versus(@players[p2])
  game.result = game_result(p1_index, p2_index)
  puts output + "\t| #{game.result.round(2)} \t| #{@players[p1].rating} \t| #{@players[p2].rating}|"
end

def run_games()
  for player_one in 0..@teams.length-2 do
    for player_two in player_one+1..@teams.length-1 do
      play(player_one,player_two) if @teams[player_one]["project"] == @teams[player_two]["project"]
    end
  end
end

def list_players
  ratings = @players.map{ |key, value| [key, value.rating]}
  ratings.sort! { |x,y| y[1] <=> x[1] }
  ratings.each do |p|
    puts "|#{p[0]} | #{p[1]} |"
  end
end

run_games
list_players
