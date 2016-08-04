module Aggregates
  def mean(nums)
    nums.reduce(:+) / nums.count.to_f
  end
end

class Numeric
  def to_percent(limit, decimal = 2)
    ((self / limit.to_f) * 100).round(decimal)
  end
end

def shortened(id)
  id.split('-').first
end
