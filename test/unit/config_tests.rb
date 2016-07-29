require 'assert'
require 'dk-dumpdb/config'

require 'dk-dumpdb/db'
# require 'test/support/test_scripts'

class Dk::Dumpdb::Config

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Config"
    setup do
      @script = FakeScript.new
      @config_class = Dk::Dumpdb::Config
    end

  end

  class InitTests < UnitTests
    desc "when init"
    setup do
      now = Factory.time
      Assert.stub(Time, :now){ now }

      @config = @config_class.new
    end
    subject{ @config }

    should have_readers :copy_dump_cmd_args, :dump_cmds, :restore_cmds
    should have_imeths :ssh, :dump_file, :source, :target, :dump, :restore
    should have_imeths :dump_cmd, :restore_cmd

    should "default its values" do
      assert_instance_of Ssh, subject.ssh
      assert_equal '', subject.ssh.value(@script)

      assert_instance_of DumpFile, subject.dump_file
      assert_equal '', subject.dump_file.value(@script)

      assert_instance_of SourceTargetDb, subject.source
      val = subject.source.value(@script)
      assert_instance_of Dk::Dumpdb::Db, val
      exp = Dk::Dumpdb::Db.new(@script.dump_file, {})
      assert_equal exp, val

      assert_instance_of SourceTargetDb, subject.target
      val = subject.target.value(@script)
      assert_instance_of Dk::Dumpdb::Db, val
      exp = Dk::Dumpdb::Db.new(@script.dump_file, {})
      assert_equal exp, val

      assert_instance_of CopyDumpCmdArgs, subject.copy_dump_cmd_args

      assert_instance_of CmdList, subject.dump_cmds
      assert_equal [], subject.dump_cmds.value(@script)

      assert_instance_of CmdList, subject.restore_cmds
      assert_equal [], subject.restore_cmds.value(@script)
    end

    should "allow setting new values" do
      value = Factory.string
      subject.ssh{ value }
      assert_equal value, subject.ssh.value(@script)

      subject.dump_file{ value }
      assert_equal value, subject.dump_file.value(@script)

      subject.source do
        { 'pw' => value }
      end
      val = subject.source.value(@script)
      exp = Dk::Dumpdb::Db.new(@script.dump_file, { 'pw' => value })
      assert_equal exp, val

      subject.target do
        { 'pw' => value }
      end
      val = subject.target.value(@script)
      exp = Dk::Dumpdb::Db.new(@script.dump_file, { 'pw' => value })
      assert_equal exp, val
    end

    should "append dump/restore cmds" do
      subject.dump{ Factory.string }
      assert_equal 1, subject.dump_cmds.value(@script).size
      assert_instance_of DumpCmd, subject.dump_cmds.first

      subject.restore{ Factory.string }
      assert_equal 1, subject.restore_cmds.value(@script).size
      assert_instance_of RestoreCmd, subject.restore_cmds.first
    end

    should "build dump/restore cmd strs" do
      cmd_str = "#{Factory.string}; pw: `:pw`"

      exp = DumpCmd.new(proc{ cmd_str }).value(@script)
      assert_equal exp, subject.dump_cmd(@script){ cmd_str }

      exp = RestoreCmd.new(proc{ cmd_str }).value(@script)
      assert_equal exp, subject.restore_cmd(@script){ cmd_str }
    end

  end

  class ValueTests < UnitTests
    desc "Value"
    setup do
      @setting = Value.new
    end
    subject{ @setting }

    should have_readers :proc
    should have_imeths :value

    should "know its proc" do
      assert_kind_of ::Proc, subject.proc
      assert_nil subject.proc.call
    end

    should "instance eval its proc in the scope of a script to return a value" do
      setting = Value.new(Proc.new{ "something: #{dump_file}" })
      assert_equal "something: #{@script.dump_file}", setting.value(@script)
    end

  end

  class SshTests < UnitTests
    desc "Ssh"

    should "be a Value" do
      assert_true Ssh < Value
    end

  end

  class DumpFileTests < UnitTests
    desc "DumpFile"

    should "be a Value" do
      assert_true DumpFile < Value
    end

  end

  class SourceTargetDbTests < UnitTests
    desc "SourceTargetDb"

    should "be a Value" do
      assert_true SourceTargetDb < Value
    end

    should "have a Db value built from a hash" do
      db_hash = { 'host' => Factory.string }
      db = SourceTargetDb.new(db_hash).value(@script)
      assert_instance_of Dk::Dumpdb::Db, db

      assert_equal db_hash['host'], db.host
      assert_includes @script.dump_file, db.to_hash[:dump_file]
    end

  end

  class CopyDumpCmdArgsTests < UnitTests
    desc "CopyDumpCmdArgs"

    should "be a Value" do
      assert_true CopyDumpCmdArgs < Value
    end

    should "know its value" do
      exp = "#{@script.source_dump_file} #{@script.target_dump_file}"
      assert_equal exp, CopyDumpCmdArgs.new.value(@script)
    end

  end

  class CmdTests < UnitTests
    desc "Cmd"

    should "be a Value" do
      assert_true Cmd < Value
    end

    should "eval and apply any placeholders to the cmd string" do
      cmd_str = Proc.new{ "dump file: `#{dump_file}`; pw: `:pw`" }

      exp = "dump file: `#{@script.dump_file}`; pw: `#{@script.source_hash['pw']}`"
      assert_equal exp, Cmd.new(cmd_str).value(@script, @script.source_hash)
    end

  end

  class DumpCmdTests < UnitTests
    desc "DumpCmd"

    should "be a Cmd" do
      assert_true DumpCmd < Cmd
    end

    should "eval and apply any source placeholders to the cmd string" do
      cmd_str = Proc.new{ "dump file: `#{dump_file}`; pw: `:pw`" }

      exp = "dump file: `#{@script.dump_file}`; pw: `#{@script.source_hash['pw']}`"
      assert_equal exp, DumpCmd.new(cmd_str).value(@script)
    end

  end

  class RestoreCmdTests < UnitTests
    desc "RestoreCmd"

    should "be a Cmd" do
      assert_true RestoreCmd < Cmd
    end

    should "eval and apply any target placeholders to the cmd string" do
      cmd_str = Proc.new{ "dump file: `#{dump_file}`; pw: `:pw`" }

      exp = "dump file: `#{@script.dump_file}`; pw: `#{@script.target_hash['pw']}`"
      assert_equal exp, RestoreCmd.new(cmd_str).value(@script)
    end

  end

  class CmdListTests < UnitTests
    desc "CmdList"
    setup do
      other_cmd = Factory.string
      @cmds = [
        Cmd.new(Proc.new{ "dump file: `#{dump_file}`; pw: `:pw`" }),
        Cmd.new(Proc.new{ other_cmd })
      ]
    end

    should "be an Array" do
      assert_kind_of ::Array, CmdList.new
    end

    should "return the commands, eval'd and placeholders applied" do
      exp = @cmds.map{ |c| c.value(@script, @script.source_hash) }
      assert_equal exp, CmdList.new(@cmds).value(@script, @script.source_hash)
    end

  end

  class FakeScript
    attr_reader :dump_file, :source_dump_file, :target_dump_file
    attr_reader :source_hash, :target_hash

    def initialize
      @dump_file        = Factory.string
      @source_dump_file = File.join(Factory.path, @dump_file)
      @target_dump_file = File.join(Factory.path, @dump_file)
      @source_hash      = { 'pw' => Factory.string }
      @target_hash      = { 'pw' => Factory.string }
    end
  end

end
