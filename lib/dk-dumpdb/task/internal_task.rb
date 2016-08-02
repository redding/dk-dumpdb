require 'dk/task'
require 'much-plugin'

module Dk::Dumpdb;end
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
          cmd! "sftp #{@dk_runner.ssh_args} #{@dk_runner.host_ssh_args[s.ssh]} " \
               "#{s.ssh}:#{args}"
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
