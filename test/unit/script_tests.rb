require 'assert'
require 'dk-dumpdb/script'

require 'much-plugin'
require 'dk-dumpdb/config'

module Dk::Dumpdb::Script

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb::Script"
    subject{ Dk::Dumpdb::Script }

    should "use much-plugin" do
      assert_includes MuchPlugin, subject
    end

  end

  class MixinTests < UnitTests
    desc "mixin"
    setup do
      @config_proc = config_proc = Proc.new do
        ssh{ "user@host" }

        dump_file{ "dump.bz2" }

        source do
          { :user        => 'admin',
            :pw          => 'secret',
            :db          => 'myapp_db',
            :output_root => '/some/source/dir'
          }
        end
        target do
          { :host        => 'localhost',
            :user        => 'admin',
            :db          => 'myapp_db',
            :output_root => '/some/target/dir'
          }
        end

        dump{ "mysqldump -u :user -p\":pw\" :db | bzip2 > :dump_file" }
        restore{ "bunzip2 -c :dump_file | mysql -u :user -p\":pw\" :db" }
      end
      @script_class = Class.new do
        include Dk::Dumpdb::Script
        config &config_proc
      end
    end
    subject{ @script_class }

    should have_imeths :config

    should "store the config proc to eval when initialized" do
      assert_equal @config_proc, subject.config
    end
  end

  class InitTests < MixinTests
    desc "when init"
    setup do
      now = Factory.time
      Assert.stub(Time, :now){ now }

      @script = @script_class.new
    end
    subject{ @script }

    should have_imeths :config
    should have_imeths :ssh, :dump_file, :source, :target, :copy_dump_cmd_args
    should have_imeths :dump_cmds, :restore_cmds
    should have_imeths :source_dump_file, :target_dump_file
    should have_imeths :source_hash, :target_hash
    should have_imeths :ssh?
    should have_imeths :dump_cmd, :restore_cmd

    should "know its config" do
      assert_instance_of Dk::Dumpdb::Config, subject.config
    end

    should "know its config values" do
      c = subject.config
      assert_equal c.ssh.value(subject),       subject.ssh
      assert_equal c.dump_file.value(subject), subject.dump_file
      assert_equal c.source.value(subject),    subject.source
      assert_equal c.target.value(subject),    subject.target

      assert_equal c.copy_dump_cmd_args.value(subject), subject.copy_dump_cmd_args

      assert_equal c.dump_cmds.value(subject),    subject.dump_cmds
      assert_equal c.restore_cmds.value(subject), subject.restore_cmds
    end

    should "demeter its source/target" do
      assert_equal subject.source.dump_file, subject.source_dump_file
      assert_equal subject.target.dump_file, subject.target_dump_file
      assert_equal subject.source.to_hash,   subject.source_hash
      assert_equal subject.target.to_hash,   subject.target_hash
    end

    should "know if it should use ssh or not" do
      assert_true subject.ssh?

      none = Class.new{ include Dk::Dumpdb::Script }
      assert_false none.new.ssh?

      empty = Class.new do
        include Dk::Dumpdb::Script
        config do
          ssh{ '' }
        end
      end
      assert_false empty.new.ssh?
    end

    should "build dump/restore cmd strs" do
      cmd_str = Factory.string

      exp = subject.config.dump_cmd(subject, &proc{ cmd_str })
      assert_equal exp, subject.dump_cmd(&proc{ cmd_str })

      exp = subject.config.restore_cmd(subject, &proc{ cmd_str })
      assert_equal exp, subject.restore_cmd(&proc{ cmd_str })
    end

  end

end
