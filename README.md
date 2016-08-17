# Dk::Dumpdb

Build Dk tasks to dump and restore your databases.

Note: this is a port of the [Dumpdb gem](https://github.com/redding/dumpdb) to work with [Dk](https://github.com/redding/dk) tasks.  The overall API/DSL is similar - you still define restore scripts but they are run using Dk tasks.

## Usage

```ruby
require 'dk-dumpdb'

class MysqlFullRestoreScript
  include Dk::Dumpdb::Script

  config do
    source do
      { :host        => 'production.example.com',
        :port        => 1234,
        :user        => 'admin',
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

    dump_file{ "dump.bz2" }

    restore{ "mysqladmin -u :user -p\":pw\" -f -b DROP :db; true" }
    restore{ "mysqladmin -u :user -p\":pw\" -f CREATE :db" }
    restore{ "bunzip2 -c :dump_file | mysql -u :user -p\":pw\" :db" }
  end

  task_desc "restore mysql data"

end
```

Dk::Dumpdb provides a framework for defining scripts that backup and restore databases.  You configure your source and target db settings.  You define the set of commands needed for your task to dump the (local or remote) source database and optionally restore the dump to the (local) target database.

### Running

Each script automatically defines its own Dk task (`<ScriptClass>::Task`) that you can configure/use directly or that you can run from your own restore task.

```ruby
# configure the dumpdb script task and use directly

require 'dk'

Dk.configure do
  task 'restore-mysql', MysqlFullRestoreScript::Task
end

# OR use your own dk task to run the dumpdb script task

class MysqlFullRestoreTask
  include Dk::Task

  def run!
    # custom logic before the script run...

    run_task MysqlFullRestoreScript::Task

    # custom logic after the script run...
  end

end

Dk.configure do
  task 'restore-mysql', MysqlFullRestoreTask
end
```

Either way, to run use Dk's CLI:

```
$ dk restore-mysql
```

Dk runs the task which runs the dump commands using source settings and runs the restore commands using target settings.  By default, Dk::Dumpdb assumes both the dump and restore commands are to be run on the local system.

### Remote dumps

To run your dump commands on a remote server, specify the optional `ssh` setting.

```ruby
class MysqlFullRestoreScript
  include Dk::Dumpdb::Script

  config do
    ssh { 'user@host' }
    # ...
  end

end
```

This tells Dk::Dumpdb to run the dump commands using ssh on a remote host and to download the dump file using sftp.

**Note**: you can configure SSH args using [Dk's config DSL](https://github.com/redding/dk#ssh_hosts-ssh_args-host_ssh_args).  These will be used by the ssh dump commands.

```ruby
Dk.configure do
  # these custom args will be on all SSH dump cmds
  ssh_args "-o ForwardAgent=yes "\
           "-o ControlMaster=auto "\
           "-o ControlPersist=60s "\
           "-o UserKnownHostsFile=/dev/null "\
           "-o StrictHostKeyChecking=no "\
           "-o ConnectTimeout=10 "\
           "-o LogLevel=quiet " \
           "-tt "
end
```

Dk::Dumpdb uses `scp` to tranfer remote dump files to the local system.  You can configure any custom scp args by setting a param:

```ruby
Dk.configure do
  scp_args = "-o ForwardAgent=yes "\
             "-o ControlMaster=auto "\
             "-o ControlPersist=60s "\
             "-o UserKnownHostsFile=/dev/null "\
             "-o StrictHostKeyChecking=no "\
             "-o ConnectTimeout=10 "\
             "-o LogLevel=quiet "
  dk_config.set_param(Dk::Dumpdb::SCP_ARGS_PARAM_NAME, scp_args)

  task 'restore-mysql', MysqlFullRestoreScript::Task
end
```

**Protip**: since scp and ssh cmds share ssh options, set those to a variable and reuse on both the ssh cmds and the scp dump file cmd:

```ruby
Dk.configure do
  # reuse thise on both the ssh and scp cmds
  ssh_opts = "-o ForwardAgent=yes "\
             "-o ControlMaster=auto "\
             "-o ControlPersist=60s "\
             "-o UserKnownHostsFile=/dev/null "\
             "-o StrictHostKeyChecking=no "\
             "-o ConnectTimeout=10 "\
             "-o LogLevel=quiet "

  ssh_args "#{ssh_opts} -tt"
  dk_config.set_param(Dk::Dumpdb::SCP_ARGS_PARAM_NAME, ssh_opts)

  task 'restore-mysql', MysqlFullRestoreScript::Task
end
```

## Define your script

Every Dk::Dumpdb script assumes there are two types of commands involved: dump commands that run using source settings and restore commands that run using target settings.  The dump commands should produce a single "dump file" (typically a compressed file or tar).  The restore commands restore the local db from the dump file.

### The Dump File

You specify the name of the dump file using the `dump_file` setting

```ruby
# ...
dump_file { "dump.bz2" }
#...
```

This tells Dk::Dumpdb what file is being generated by the dump and will be used in the restore.  The dump commands should produce it.  The restore commands should use it.

### Dump commands

Dump commands are system commands that should produce the dump file.

```ruby
# ...
dump { "mysqldump -u :user -p :pw :db | bzip2 > :dump_file" }
#...
```

### Restore commands

Restore commands are system commands that should restore the local db from the dump file.

```ruby
# ...
restore { "mysqladmin -u :user :pw -f -b DROP :db; true" }   # drop the local db, whether it exists or not
restore { "mysqladmin -u :user :pw -f CREATE :db" }          # recreate the local db
restore { "bunzip2 -c :dump_file | mysql -u :user :pw :db" } # unzip the dump file and apply it to the db
#...
```

### Command Placeholders

Dump and restore commands are templated.  You define the command with placeholders and appropriate setting values are substituted in when the task is run.

Command placeholders should correspond with keys in the source or target settings.  Dump commands use the source settings and restore commands use the target settings.

### Special Placeholders

There are two special placeholders that are added to the source and target settings automatically:

* `:output_dir`
dir the dump file is written to or read from (depending on whether dumping or restoring).  This is generated by the task instance.  By default, no specific root value is used - pass in a `:output_root` value to the source and target to specify one.

* `:dump_file`
path of the dump file - uses the :output_dir setting

You should at least use the `:dump_file` placeholder in your dump and restore commands to ensure proper dump handling and usage.

```ruby
dump_file { "dump.bz2" }

dump    { "mysqldump :db | bzip2 > :dump_file" }
restore { "bunzip2 -c :dump_file | mysql :db" }
```

## Source / Target settings

A Dk::Dumpdb task needs to be told about its source and target settings.  You tell it these when you define your task:

```ruby
class MysqlFullRestoreScript
  include Dk::Dumpdb::Script

  config do
    source do
      { :user      => 'something',
        :pw        => 'secret',
        :db        => 'something_production',
        :something => 'else'
      }
    end

    target do
      { :user => 'root',
        :pw   => 'supersecret',
        :db   => 'something_development'
      }
    end

    # ...
  end

end
```

Any settings keys can be used as command placeholders in dump and restore commands.

### Building Commands

The task DSL settings methods all take a proc as their argument.  This is because the procs are lazy-eval'd in the scope of the task instance.  This allows you to use interpolation to help build commands with dynamic data.

Take this example where you want your dump task to honor ignored tables.

```ruby
class MysqlFullRestoreScript
  include Dk::Dumpdb::Script

  config do
    # ...
    dump { "mysqldump -u :user -p :pw :db #{ignored_tables} | bzip2 > :dump_file" }
    # ...
  end

  def initialize(opts={})
    opts[:ignored_tables] ||= []
    @opts = opts
  end

  def ignored_tables
    @opts[:ignored_tables].map{ |t| "--ignore-table=#{source.db}.#{t}" }.join(' ')
  end

end
```

## Installation

Add this line to your application's Gemfile:

    gem 'dk-dumpdb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dk-dumpdb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
