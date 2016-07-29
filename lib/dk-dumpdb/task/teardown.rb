require 'dk-dumpdb/task/internal_task'

module Dk::Dumpdb::Task

  class Teardown
    include Dk::Dumpdb::Task::InternalTask

    desc "(dk-dumpdb) teardown a script run"

    def run!
      # TODO
      # source_cmd!(params['script'].dump_cmd{ "rm -rf #{source.output_dir}" })
      # target_cmd!(params['script'].restore_cmd{ "rm -rf #{target.output_dir}" })
    end

  end

end
