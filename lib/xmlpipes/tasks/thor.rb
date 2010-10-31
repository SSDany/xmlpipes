require 'thor' unless defined?(Thor)

module XMLPipes #:nodoc:
  class Cli < Thor

    include Thor::Actions

    def initialize(*args, &block)
      super; apply_configuration
    end

    class_option :quiet         , :type => :boolean , :aliases => '-q', :desc => 'run command quietly.'
    class_option :environment   , :type => :string  , :aliases => '-e', :desc => 'environment'

    desc "sphinx start", "Start search daemon."
    method_option :force, :type => :boolean, :aliases => '-f', :desc => 'Force restart.'

    def start
      if controller.running?
        say "searchd is already running."
        restart if options.force? || yes?("Force restart? [yn]")
        return
      end
      start_searchd
    end

    desc "sphinx restart", "Restart search daemon."
    def restart
      stop
      sleep(0.25)
      start_searchd
    end

    desc "sphinx stop [options]", "Stop search daemon."
    def stop
      unless controller.running?
        say "searchd is not running."
        return
      end
      pid = controller.pid
      controller.stop
      say "Stopped search daemon (pid #{pid})."
    end

    desc "sphinx configure", "Generate sphinx configuration."
    def configure
      create_file(configuration.controller.path, configuration.render)
      empty_directory(File.dirname(configuration.searchd.log))
      empty_directory(File.dirname(configuration.searchd.pid_file))
      empty_directory(configuration.searchd_file_path)
      empty_directory(configuration.pipes_path)
    end

    private

    def configuration
      XMLPipes::Configuration.instance
    end

    def controller
      configuration.controller
    end

    def start_searchd
      configure unless File.file?(controller.path)
      controller.start
      say "Started successfully (pid #{controller.pid})." if controller.running?
    end

    def apply_configuration
      XMLPipes::Configuration.configure { |c|
        c.root = self.destination_root
        c.environment = options.environment if options.environment
      }
    end

    def say_status(*args,&block)
      super unless options.quiet?
    end

    def say(*args,&block)
      super unless options.quiet?
    end

  end
end