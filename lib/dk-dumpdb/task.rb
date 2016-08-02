require 'dk/task'
require 'much-plugin'
require 'dk-dumpdb/task/copy_dump'
require 'dk-dumpdb/task/dump'
require 'dk-dumpdb/task/restore'
require 'dk-dumpdb/task/setup'
require 'dk-dumpdb/task/teardown'

module Dk::Dumpdb

  module Task
    include MuchPlugin

    plugin_included do
      include Dk::Task
      include InstanceMethods
      extend ClassMethods

    end

    module InstanceMethods

      def run!
        script = self.class.script_class.new

        run_task Setup,      'script' => script
        begin
          run_task Dump,     'script' => script
          run_task CopyDump, 'script' => script
          run_task Restore,  'script' => script
        ensure
          run_task Teardown, 'script' => script
        end
      end

    end

    module ClassMethods

      def script_class(value = nil)
        @script_class = value if !value.nil?
        @script_class
      end

    end

    module TestHelpers
      include MuchPlugin

      plugin_included do
        include Dk::Task::TestHelpers
      end

    end

  end

end
