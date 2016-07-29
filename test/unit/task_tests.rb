require 'assert'
require 'dk-dumpdb/task'

require 'dk/task'
require 'much-plugin'
require 'dk-dumpdb/task/copy_dump'
require 'dk-dumpdb/task/dump'
require 'dk-dumpdb/task/restore'
require 'dk-dumpdb/task/setup'
require 'dk-dumpdb/task/teardown'

module Dk::Dumpdb::Task

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Task"
    subject{ Dk::Dumpdb::Task }

    should "use much-plugin" do
      assert_includes MuchPlugin, subject
    end

  end

  class MixinTests < UnitTests
    desc "mixin"
    setup do
      @task_class = Class.new do
        include Dk::Dumpdb::Task

      end
    end
    subject{ @task_class }

    should "be a Dk task" do
      assert_includes Dk::Task, subject
    end

  end

  class InitTests < MixinTests
    include Dk::Task::TestHelpers

    desc "when init"
    setup do
      @runner = test_runner(@task_class)
      @task   = @runner.task
    end
    subject{ @task }

  end

  class RunTests < InitTests
    desc "and run"
    setup do
      @runner.run
    end

    should "do something"

  end

  class TestHelpersTets < UnitTests
    desc "TestHelpers"
    setup do
      @context_class = Class.new{ include Dk::Dumpdb::Task::TestHelpers }
      @context = @context_class.new
    end
    subject{ @context }

    should "include Dk task test hepers" do
      assert_includes Dk::Task::TestHelpers, @context_class
    end

  end

end
