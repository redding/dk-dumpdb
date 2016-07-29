require 'much-plugin'
require 'dk-dumpdb/config'

module Dk::Dumpdb

  module Script
    include MuchPlugin

    plugin_included do
      include InstanceMethods
      extend ClassMethods

    end

    module InstanceMethods

      def config
        @config ||= Config.new.tap do |config|
          config.instance_eval(&self.class.config || proc{})
        end
      end

      def ssh;       @ssh       ||= config.ssh.value(self);       end
      def dump_file; @dump_file ||= config.dump_file.value(self); end
      def source;    @source    ||= config.source.value(self);    end
      def target;    @target    ||= config.target.value(self);    end

      def copy_dump_cmd_args
        @copy_dump_cmd_args ||= config.copy_dump_cmd_args.value(self)
      end

      def dump_cmds;    @dump_cmds    ||= config.dump_cmds.value(self);    end
      def restore_cmds; @restore_cmds ||= config.restore_cmds.value(self); end

      def source_dump_file; self.source.dump_file; end
      def target_dump_file; self.target.dump_file; end

      def source_hash; self.source.to_hash; end
      def target_hash; self.target.to_hash; end

      def ssh?
        self.ssh && !self.ssh.empty?
      end

      def dump_cmd(&block);   config.dump_cmd(self, &block);    end
      def restore_cmd(&block) config.restore_cmd(self, &block); end

    end

    module ClassMethods

      def config(&block)
        @config_block = block if !block.nil?
        @config_block
      end

    end

  end

end