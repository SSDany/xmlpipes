require 'singleton'

module XMLPipes #:nodoc:
  class Configuration
    include Singleton

    IndexOptions = :docinfo, :mlock,
        :morphologies, :min_stemming_len, :stopword_files, :wordform_files,
        :exception_files, :min_word_len, :charset_dictpath, :charset_type,
        :charset_table, :ignore_characters, :min_prefix_len, :min_infix_len,
        :prefix_field_names, :infix_field_names, :enable_star, :expand_keywords,
        :ngram_len, :ngram_characters, :phrase_boundaries,
        :phrase_boundary_step, :blend_chars, :html_strip, :html_index_attrs,
        :html_remove_element_tags, :preopen, :ondisk_dict, :inplace_enable,
        :inplace_hit_gap, :inplace_docinfo_gap, :inplace_reloc_factor,
        :inplace_write_factor, :index_exact_words, :overshort_step,
        :stopwords_step, :hitless_words

    attr_accessor :root
    attr_accessor :searchd_file_path
    attr_accessor :pipes_path
    attr_accessor :environment

    attr_reader :index_options
    attr_reader :configuration
    attr_reader :controller

    @settings = :searchd_file_path, :pipes_path, 
                :address, :port,
                :bin_path, :searchd_binary_name, :indexer_binary_name,
                :config_file

    class << self
      attr_reader :settings
    end

    def initialize(root = Dir.pwd)
      @environment = 'development'
      @indexed = []
      @root = root
      reset
    end

    def self.configure(&block)
      yield(instance) if block_given?
      instance.reset
      instance.apply_config
    end

    def reset
      @configuration                    = Riddle::Configuration.new
      @index_options                    = { :charset_type => 'utf-8' }
      self.address                      = '127.0.0.1'
      self.port                         = 9312

      @configuration.searchd.pid_file   = "#{root}/tmp/searchd.#{environment}.pid"
      @configuration.searchd.log        = "#{root}/log/searchd.log"
      @configuration.searchd.query_log  = "#{root}/log/searchd.query.log"
      @searchd_file_path                = "#{root}/sphinx/#{environment}"
      @pipes_path                       = "#{root}/tmp/#{environment}"

      @controller = XMLPipes::Controller.new @configuration, "#{root}/config/#{environment}.sphinx.conf"
    end

    def apply_config(path = nil)
      path ||= "#{root}/config/sphinx.xmlpipes.yml"
      return unless File.exists?(path)

      config = YAML::load_file(path)[environment]
      config.each do |key,value|
        case key.to_sym
        when :searchd
          apply_section_settings @configuration.searchd, value
        when :indexer
          apply_section_settings @configuration.indexer, value
        when *self.class.settings
          send("#{key}=", value)
        else
          k = key.to_sym
          @index_options[k] = value if IndexOptions.include?(k)
        end
      end unless config.nil?

      # http://sphinxsearch.com/docs/current.html#conf-min-prefix-len
      #
      # Prefix indexing allows to implement wildcard searching by 'wordstart*'
      # wildcards (refer to enable_star option for details on wildcard syntax).
      # When mininum prefix length is set to a positive number, indexer will
      # index all the possible keyword prefixes (ie. word beginnings) in addition
      # to the keywords themselves. Too short prefixes (below the minimum allowed
      # length) will not be indexed.

      @index_options[:min_prefix_len] = 1 if @index_options[:enable_star]

    end

    def apply_section_settings(section, settings = {})
      return unless Hash === settings && !settings.empty?
      settings.each do |key, value|
        setter = :"#{key}="
        self.send(setter, value) if self.class.settings.include?(key.to_sym) # EG port, address
        section.send(setter, value) if section.class.settings.include?(key.to_sym)
      end
    end

    private :apply_section_settings

    def client
      cli = Riddle::Client.new(@address, @port)
      cli.max_matches = @configuration.searchd.max_matches || 1000
      cli
    end

    def indexer
      @configuration.indexer
    end

    def searchd
      @configuration.searchd
    end

    def address
      @address
    end

    def address=(address)
      @address = address
      @configuration.searchd.address = address
    end

    def port
      @port
    end

    def port=(port)
      @port = port
      @configuration.searchd.port = port
    end

    def allow_star?
      !!@index_options[:enable_star]
    end

    def config_file
      @controller.path
    end

    def config_file=(file)
      @controller.path = file
    end

    def bin_path
      @controller.bin_path
    end

    def bin_path=(path)
      @controller.bin_path = path
    end

    def searchd_binary_name
      @controller.searchd_binary_name
    end

    def searchd_binary_name=(name)
      @controller.searchd_binary_name = name
    end

    def indexer_binary_name
      @controller.indexer_binary_name
    end

    def indexer_binary_name=(name)
      @controller.indexer_binary_name = name
    end

    protected *@settings.map { |sym| "#{sym}=" }

    def indexed(klass)
      @indexed << klass unless @indexed.include?(klass)
    end

    def render
      @configuration.indexes.clear
      @indexed.each { |klass| @configuration.indexes.concat(klass.to_riddle) }
      @configuration.render
    end

    def build
      File.open(@controller.path, File::WRONLY|File::TRUNC|File::CREAT) { |c| c << render }
    end

  end
end