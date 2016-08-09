class Stats
  module Support
    def culture_contrib(opts = {})
      scores = data.culture_contrib
                   .subject(opts[:player_id])
                   .cycle(opts[:cycle_no])
                   .values(&:to_i)

      mean(scores).to_percent(7)
    end

    def learning_support(opts = {})
      scores = data.learning_support
                   .subject(opts[:player_id])
                   .cycle(opts[:cycle_no])
                   .values(&:to_i)

      mean(scores).to_percent(7)
    end
  end
end
