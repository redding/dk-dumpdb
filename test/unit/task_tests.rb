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

    should have_imeths :script_class

    should "be a Dk task" do
      assert_includes Dk::Task, subject
    end

    should "know its script class" do
      assert_nil subject.script_class

      value = Factory.string
      subject.script_class value

      assert_equal value, subject.script_class
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
      @task_class.script_class Factory.script_class

      @script_init_with = nil
      @script = @task_class.script_class.new
      Assert.stub(@task_class.script_class, :new) do |*args|
        @script_init_with = args
        @script
      end

      @runner.run
    end
    subject{ @runner }

    should "build an instance of its script class and run it" do
      assert_equal 5, subject.runs.size

      setup, dump, copydump, restore, teardown = subject.runs

      assert_equal Setup,    setup.task_class
      assert_equal Dump,     dump.task_class
      assert_equal CopyDump, copydump.task_class
      assert_equal Restore,  restore.task_class
      assert_equal Teardown, teardown.task_class

      assert_equal [@runner.params], @script_init_with

      subject.runs.each do |task_run|
        assert_equal @script, task_run.params['script']
      end
    end

  end

  class TestHelpersTets < UnitTests
    desc "TestHelpers"
    setup do
      @context_class = Class.new{ include Dk::Dumpdb::Task::TestHelpers }
      @context = @context_class.new
    end
    subject{ @context }

    should "include Dk task test helpers" do
      assert_includes Dk::Task::TestHelpers, @context_class
    end

  end

end
