require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task

  class CopyDump
    include Dk::Dumpdb::Task::InternalTask

    desc "(dk-dumpdb) copy the given script's dump file from source to target"

    def run!
      copy_cmd! params['script'].copy_dump_cmd_args
    end

  end

end
