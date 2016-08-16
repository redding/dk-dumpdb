require 'dk/task'
require 'much-plugin'
require 'dk-dumpdb'

module Dk::Dumpdb::Task

  module InternalTask
    include MuchPlugin

    plugin_included do
      include Dk::Task
      include InstanceMethods

    end

    module InstanceMethods

      private

      def source_cmd!(cmd_str)
        if params['script'].ssh?
          ssh!(cmd_str, :hosts => params['script'].ssh)
        else
          cmd!(cmd_str)
        end
      end

      def copy_cmd!(args)
        if (s = params['script']).ssh?
          cmd! "scp #{try_param(Dk::Dumpdb::SCP_ARGS_PARAM_NAME)} #{s.ssh}:#{args}"
        else
          cmd! "cp #{args}"
        end
      end

      def target_cmd!(cmd_str)
        cmd!(cmd_str)
      end

    end

  end

end
