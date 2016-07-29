require 'dk-dumpdb/db'

module Dk::Dumpdb

  class Config

    attr_reader :copy_dump_cmd_args, :dump_cmds, :restore_cmds

    def initialize
      @ssh       = Ssh.new('')
      @dump_file = DumpFile.new('')
      @source    = SourceTargetDb.new({})
      @target    = SourceTargetDb.new({})

      @copy_dump_cmd_args = CopyDumpCmdArgs.new

      @dump_cmds    = CmdList.new([])
      @restore_cmds = CmdList.new([])
    end

    def ssh(&block)
      @ssh = Ssh.new(block) if !block.nil?
      @ssh
    end

    def dump_file(&block)
      @dump_file = DumpFile.new(block) if !block.nil?
      @dump_file
    end

    def source(&block)
      @source = SourceTargetDb.new(block) if !block.nil?
      @source
    end

    def target(&block)
      @target = SourceTargetDb.new(block) if !block.nil?
      @target
    end

    def dump(&block);    @dump_cmds    << DumpCmd.new(block);    end
    def restore(&block); @restore_cmds << RestoreCmd.new(block); end

    def dump_cmd(script, &block);   DumpCmd.new(block).value(script);    end
    def restore_cmd(script, &block) RestoreCmd.new(block).value(script); end

    class Value

      attr_reader :proc

      def initialize(proc = nil)
        @proc = proc.kind_of?(::Proc) ? proc : Proc.new{ proc }
      end

      def value(script)
        script.instance_eval(&@proc)
      end

    end

    class Ssh < Value; end

    class DumpFile < Value; end

    class SourceTargetDb < Value

      def value(script)
        hash = super
        Db.new(script.dump_file, hash)
      end

    end

    class CopyDumpCmdArgs < Value

      def value(script)
        "#{script.source_dump_file} #{script.target_dump_file}"
      end

    end

    class Cmd < Value

      def value(script, placeholder_vals)
        hsub(super(script), placeholder_vals)
      end

      private

      def hsub(string, hash)
        hash.inject(string){ |new_str, (k, v)| new_str.gsub(":#{k}", v.to_s) }
      end

    end

    class DumpCmd < Cmd

      def value(script, placeholder_vals = {})
        super(script, script.source_hash.merge(placeholder_vals))
      end

    end

    class RestoreCmd < Cmd

      def value(script, placeholder_vals = {})
        super(script, script.target_hash.merge(placeholder_vals))
      end

    end

    class CmdList < ::Array

      def value(script, placeholder_vals = {})
        self.map{ |cmd| cmd.value(script, placeholder_vals) }
      end

    end

  end

end
