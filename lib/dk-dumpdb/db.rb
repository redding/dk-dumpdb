module Dk; end
module Dk::Dumpdb

  class Db

    DEFAULT_VALUE = ''.freeze

    def initialize(dump_file_name = nil, values = nil)
      dump_file_name = dump_file_name || 'dump.output'
      @values        = dk_dumpdb_symbolize_keys(values)

      [:host, :port, :user, :pw, :db, :output_root].each do |key|
        @values[key] ||= DEFAULT_VALUE
      end

      @values[:output_dir] = dk_dumpdb_build_output_dir(
        self.output_root,
        self.host,
        self.db
      )
      @values[:dump_file] = File.join(self.output_dir, dump_file_name)
    end

    def to_hash; @values; end

    def method_missing(meth, *args, &block)
      if @values.has_key?(meth.to_sym)
        @values[meth.to_sym]
      else
        super
      end
    end

    def respond_to?(meth)
      @values.has_key?(meth.to_sym) || super
    end

    def ==(other_db)
      if other_db.kind_of?(Db)
        self.to_hash == other_db.to_hash
      else
        super
      end
    end

    private

    def dk_dumpdb_build_output_dir(output_root, host, database)
      dir_name = dk_dumpdb_build_output_dir_name(host, database)
      if output_root && !output_root.to_s.empty?
        File.join(output_root, dir_name)
      else
        dir_name
      end
    end

    def dk_dumpdb_build_output_dir_name(host, database)
      [host, database, Time.now.to_f].map(&:to_s).reject(&:empty?).join("__")
    end

    def dk_dumpdb_symbolize_keys(values)
      (values || {}).inject({}) do |h, (k, v)|
        h.merge(k.to_sym => v)
      end
    end

  end

end
