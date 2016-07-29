require 'assert/factory'
require 'dk-dumpdb/script'

module Factory
  extend Assert::Factory

  def self.script_class(&config_proc)
    Class.new do
      include Dk::Dumpdb::Script
      config &config_proc
    end
  end

  def self.script(script_class = nil, &config_proc)
    (script_class || self.script_class(&config_proc)).new
  end

end
