module CycleHours
  CYCLE_HOURS = {
    14 => 32, # (start 10/10) indig. people's day
    18 => 32, # (start 11/07) veteran's day
    20 => 20, # (start 11/21) thanksgiving week
  }

  DEFAULT_CYCLE_HOURS = 40

  def hours_for_cycle(cycle_no)
    CYCLE_HOURS[cycle_no.to_i] || DEFAULT_CYCLE_HOURS
  end
end
