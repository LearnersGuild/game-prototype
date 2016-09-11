class StatsFromData
  module StatType
    # An abstract module for allowing stat types to be included in StatsFromData module
    def included(base)
      StatsFromData.types[self.to_s.split('::').last.downcase.to_sym] = self.instance_methods
    end
  end
end
