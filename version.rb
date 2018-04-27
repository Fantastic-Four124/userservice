module Version
  @VERSION = "1.0.0"
  class << self
    attr_reader :VERSION
  end
end
