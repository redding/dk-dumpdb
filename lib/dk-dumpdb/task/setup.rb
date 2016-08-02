require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task

  class Setup
    include Dk::Dumpdb::Task::InternalTask

    desc "(dk-dumpdb) setup a script run"

    def run!
      source_cmd!(params['script'].dump_cmd{ "mkdir -p #{source.output_dir}" })
      target_cmd!(params['script'].restore_cmd{ "mkdir -p #{target.output_dir}" })
    end

  end

end
