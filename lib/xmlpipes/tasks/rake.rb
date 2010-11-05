namespace :xmlpipes do

  desc "Generate the Sphinx configuration."
  task :configure => :prepare do
    FileUtils.mkdir_p File.dirname(@config.config_file)
    FileUtils.mkdir_p File.dirname(@config.searchd.log)
    FileUtils.mkdir_p File.dirname(@config.searchd.pid_file)
    FileUtils.mkdir_p @config.searchd_file_path
    FileUtils.mkdir_p @config.pipes_path

    puts "Generating Configuration to #{@config.config_file}"
    @config.build
  end

  desc "Start a Sphinx searchd daemon."
  task :start => :prepare do
    Rake::Task['xmlpipes:configure'].invoke unless File.file?(@config.controller.path)
    raise RuntimeError, "searchd is already running." if @config.controller.running?
    @config.controller.start
    if @config.controller.running?
      puts "Started successfully (pid #{@config.controller.pid})."
    else
      puts "Failed to start searchd daemon. Check #{@config.searchd.log}"
    end
  end

  desc "Stop Sphinx."
  task :stop => :prepare do
    if @config.controller.running?
      pid = @config.controller.pid
      @config.controller.stop
      puts "Stopped search daemon (pid #{pid})."
    else
      puts "searchd is not running"
    end
  end

  task :prepare do
    @config = XMLPipes::Configuration.instance
    @config.apply_config
  end

end