module Version
  @VERSION = "0.5.0"
  class << self
    attr_reader :VERSION
  end
end
