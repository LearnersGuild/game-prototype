class Stats
  module StatType
    # An abstract module for allowing stat types to be included in Stats module
    def included(base)
      Stats.types[self.to_s.split('::').last.downcase.to_sym] = self.instance_methods
    end
  end
end
