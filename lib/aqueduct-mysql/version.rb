module Aqueduct
  module Mysql
    module VERSION
      MAJOR = 0
      MINOR = 2
      TINY = 1
      BUILD = "pre" # nil, "pre", "rc", "rc2"

      STRING = [MAJOR, MINOR, TINY, BUILD].compact.join('.')
    end
  end
end
