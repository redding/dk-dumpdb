require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task

  class Restore
    include Dk::Dumpdb::Task::InternalTask

    desc "(dk-dumpdb) run the given script's restore cmds"

    def run!
      params['script'].restore_cmds.each{ |cmd_str| target_cmd!(cmd_str) }
    end

  end

end
