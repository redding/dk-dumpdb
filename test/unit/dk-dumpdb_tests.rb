require 'assert'

module Dk::Dumpdb

  class UnitTests < Assert::Context
    desc "Dk::Dumpdb"
    subject{ Dk::Dumpdb }

    should "know its scp args param name" do
      exp = "dk-dumpdb_scp_args"
      assert_equal exp, subject::SCP_ARGS_PARAM_NAME
    end

  end

end
