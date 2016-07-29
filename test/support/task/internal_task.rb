require 'dk/task'
require 'much-plugin'
require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task::InternalTask

  module TestHelpers
    include MuchPlugin

    plugin_included do
      include Dk::Task::TestHelpers
      include InstanceMethods

    end

    module InstanceMethods

      def set_dk_dumpdb_script_param(*args, &block)
        @params ||= {}
        @params['script'] = Factory.script(*args, &block)
      end

    end

  end

end
