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
        attr_writer :cp_cmd_args
        def run!
          source_cmd! "a source cmd"
          copy_cmd! @cp_cmd_args
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
      @cp_args = "#{Factory.file_path} #{Factory.file_path}"
      @params  = {}
    end

    should "run source/target/copy cmds as local Dk cmds if not an ssh script" do
      @params['script'] = Factory.script
      runner = test_runner(@task_class, :params => @params)
      task   = runner.task

      task.cp_cmd_args = @cp_args
      runner.run
      assert_equal 3, runner.runs.size

      source_cmd, copy_cmd, target_cmd = runner.runs
      assert_false source_cmd.ssh?
      assert_false target_cmd.ssh?
      assert_false copy_cmd.ssh?

      assert_equal "a source cmd", source_cmd.cmd_str
      assert_equal "a target cmd", target_cmd.cmd_str

      exp = "cp #{@cp_args}"
      assert_equal exp, copy_cmd.cmd_str
    end

    should "run source/copy cmds as remote Dk cmds if an ssh script" do
      @params['script'] = Factory.script{ ssh{ "hostname" } }
      @ssh_args         = Factory.string
      @host_ssh_args    = { "hostname" => Factory.string }

      runner = test_runner(@task_class, {
        :params        => @params,
        :ssh_args      => @ssh_args,
        :host_ssh_args => @host_ssh_args
      })
      task   = runner.task

      task.cp_cmd_args = @cp_args
      runner.run
      assert_equal 3, runner.runs.size

      source_ssh, copy_cmd, target_cmd = runner.runs
      assert_true  source_ssh.ssh?
      assert_false target_cmd.ssh?
      assert_false copy_cmd.ssh?

      assert_equal [@params['script'].ssh], source_ssh.cmd_opts[:hosts]

      assert_equal "a source cmd", source_ssh.cmd_str
      assert_equal "a target cmd", target_cmd.cmd_str

      exp = "sftp #{@ssh_args} #{@host_ssh_args[@params['script'].ssh]} " \
            "#{@params['script'].ssh}:#{@cp_args}"
      assert_equal exp, copy_cmd.cmd_str
    end

  end

end
