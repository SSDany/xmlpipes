module XMLPipes #:nodoc:
  class Index

    attr_reader :name
    attr_reader :sources
    attr_reader :klass

    def initialize(name, klass)
      @name     = name.to_sym
      @sources  = []
      @options  = {}
      @klass    = klass
      @schema   = Source::Schema.new(self)
    end

    def set(key, value)
      @options[key.to_sym] = value
    end

    def docinfo
      @options[:docinfo] || (@schema.attrs.empty? ? nil : :extern)
    end

    def enable_deltas
      @has_deltas = true
    end

    def has_deltas?
      !!@has_deltas
    end

    def schema(&block)
      yield(@schema) if block_given?
      source if @sources.empty?
      @schema
    end

    def source(source_name = nil, &block)
      source = Source.new(source_name || @name, self)
      yield(source) if block_given?
      @sources.reject! { |s| s.name == source.name }
      @sources << source
    end

    def fields
      @schema.fields
    end

    def attributes
      @schema.attrs
    end

    alias :attrs :attributes

    def core_name
      "#{@name}_core"
    end

    def delta_name
      "#{@name}_delta"
    end

    def to_riddle
      has_deltas? ? [core, delta, distributed] : [core, distributed]
    end

    private

    def config
      Configuration.instance
    end

    def delta
      index = Riddle::Configuration::Index.new(delta_name)
      index.path = File.join(config.searchd_file_path, delta_name)
      index.sources = @sources.map { |src| src.delta }
      index.parent = core_name
      index
    end

    def core
      index = Riddle::Configuration::Index.new(core_name)
      index.path = File.join(config.searchd_file_path, core_name)
      index.sources = @sources.map { |src| src.core }

      Configuration::IndexOptions.each do |key|
        value = @options[key] || config.index_options[key]
        index.send("#{key}=", value) if value
      end

      index.docinfo ||= docinfo
      index
    end

    def distributed
      index = Riddle::Configuration::DistributedIndex.new(@name.to_s)
      index.local_indexes << core_name
      index.local_indexes << delta_name if has_deltas?
      index
    end

  end
end