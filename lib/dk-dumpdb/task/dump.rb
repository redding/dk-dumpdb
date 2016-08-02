require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task

  class Dump
    include Dk::Dumpdb::Task::InternalTask

    desc "(dk-dumpdb) run the given script's dump cmds"

    def run!
      params['script'].dump_cmds.each{ |cmd_str| source_cmd!(cmd_str) }
    end

  end

end
