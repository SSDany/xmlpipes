namespace :xmlpipes do

  desc "Generate the Sphinx configuration."
  task :configure => :prepare do
    config = XMLPipes::Configuration.instance
    FileUtils.mkdir_p File.dirname(config.config_file)
    puts "Generating Configuration to #{config.config_file}"
    config.build
  end

  task :prepare do
    XMLPipes::Configuration.instance.apply_config
  end

end