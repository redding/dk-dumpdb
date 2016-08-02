require 'assert'
require 'dk-dumpdb/task/dump'

require 'test/support/task/internal_task'

class Dk::Dumpdb::Task::Dump

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Task::Dump"
    setup do
      @task_class = Dk::Dumpdb::Task::Dump
    end
    subject{ @task_class}

    should "be an internal task" do
      assert_includes Dk::Dumpdb::Task::InternalTask, subject
    end

    should "know its description" do
      exp = "(dk-dumpdb) run the given script's dump cmds"
      assert_equal exp, subject.description
    end

  end

  class InitTests < UnitTests
    include Dk::Dumpdb::Task::InternalTask::TestHelpers

    desc "when init"
    setup do
      now = Factory.time
      Assert.stub(Time, :now){ now }

      @dump_cmds = dump_cmds = Factory.integer(3).times.map{ Factory.string }
      set_dk_dumpdb_script_param do
        dump_cmds.each do |cmd_str|
          dump{ cmd_str }
        end
      end
      @runner = test_runner(@task_class, :params => @params)
    end

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @runner.run
    end
    subject{ @runner }

    should "run all dump cmds" do
      assert_equal @dump_cmds, subject.runs.map(&:cmd_str)
    end

  end

end
