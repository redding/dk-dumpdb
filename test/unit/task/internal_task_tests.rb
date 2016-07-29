require 'assert'
require 'dk-dumpdb/task/internal_task'

require 'dk'
require 'dk/task'
require 'much-plugin'

module Dk::Dumpdb::Task::InternalTask

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Task::InternalTask"
    setup do
      @module = Dk::Dumpdb::Task::InternalTask
    end
    subject{ @module }

    should "use much-plugin" do
      assert_includes MuchPlugin, subject
    end

  end

  class MixinTests < UnitTests
    desc "mixin"
    setup do
      @task_class = Class.new do
        include Dk::Dumpdb::Task::InternalTask
        def run!
          source_cmd! "a source cmd"
          target_cmd! "a target cmd"
        end
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
      @params = {}
    end

    should "run source/target cmds as local Dk cmds if not an ssh script" do
      @params['script'] = Factory.script
      runner = test_runner(@task_class, :params => @params)
      task   = runner.task

      runner.run
      assert_equal 2, runner.runs.size

      source_cmd, target_cmd = runner.runs
      assert_false source_cmd.ssh?
      assert_false target_cmd.ssh?
      assert_equal "a source cmd", source_cmd.cmd_str
      assert_equal "a target cmd", target_cmd.cmd_str
    end

    should "run source cmds as remote Dk cmds if an ssh script" do
      @params['script'] = Factory.script{ ssh{ "hostname" } }
      runner = test_runner(@task_class, :params => @params)
      task   = runner.task

      runner.run
      assert_equal 2, runner.runs.size

      source_ssh, target_cmd = runner.runs
      assert_true  source_ssh.ssh?
      assert_false target_cmd.ssh?
      assert_equal "a source cmd", source_ssh.cmd_str
      assert_equal "a target cmd", target_cmd.cmd_str

      assert_equal [@params['script'].ssh], source_ssh.cmd_opts[:hosts]
    end

  end

end
