require 'assert'
require 'dk-dumpdb/task/copy_dump'

require 'test/support/task/internal_task'

class Dk::Dumpdb::Task::CopyDump

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Task::CopyDump"
    setup do
      @task_class = Dk::Dumpdb::Task::CopyDump
    end
    subject{ @task_class}

    should "be an internal task" do
      assert_includes Dk::Dumpdb::Task::InternalTask, subject
    end

    should "know its description" do
      exp = "(dk-dumpdb) copy the given script's dump file from source to target"
      assert_equal exp, subject.description
    end

  end

  class InitTests < UnitTests
    include Dk::Dumpdb::Task::InternalTask::TestHelpers

    desc "when init"
    setup do
      now = Factory.time
      Assert.stub(Time, :now){ now }

      set_dk_dumpdb_script_param
      @runner = test_runner(@task_class, :params => @params)
    end

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @runner.run
    end
    subject{ @runner }

    should "run a cmd to copy the dump" do
      assert_equal 1, subject.runs.size
      cp_dump = subject.runs.first

      exp = @params['script'].copy_dump_cmd_args
      assert_match /#{exp}\Z/, cp_dump.cmd_str
    end

  end

end
