require 'assert'
require 'dk-dumpdb/task/setup'

require 'test/support/task/internal_task'

class Dk::Dumpdb::Task::Setup

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Task::Setup"
    setup do
      @task_class = Dk::Dumpdb::Task::Setup
    end
    subject{ @task_class}

    should "be an internal task" do
      assert_includes Dk::Dumpdb::Task::InternalTask, subject
    end

    should "know its description" do
      exp = "(dk-dumpdb) setup a script run"
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

    should "do something"

  end

end
