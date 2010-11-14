require 'xmlpipes/collection'

module XMLPipes #:nodoc:
  class Search < Collection

    SEPARATOR = ' '.freeze

    def initialize(*args)
      @array        = []
      @classes      = []
      @filters      = []
      @sort_by      = []
      @conditions   = ''
      @_match_mode  = :all
      @_sort_mode   = :relevance
      apply_options Hash === args.last ? args.pop : {}
      @args         = args.flatten
    end

    # source:
    # ThinkingSphinx::Search#query
    def query
      @query ||= begin
        q = @args.join(SEPARATOR) << @conditions
        q = star_query(q) if @options[:star]
        q.strip
      end
    end

    def where(conditions = {})
      clone.apply_conditions(conditions)
    end

    def with(options = {})
      clone.apply_filters(false, options)
    end

    def without(options = {})
      clone.apply_filters(true, options)
    end

    def order(value)
      clone.apply_order(value)
    end

    def match_mode
      @options[:match_mode] || @_match_mode
    end

    def sort_mode
      case @options[:sort_mode]
      when :asc
        :attr_asc
      when :desc
        :attr_desc
      when nil
        @_sort_mode
      else
        @options[:sort_mode]
      end
    end

    def search_offset
      @options[:offset]
    end

    def offset(value)
      copy = clone
      copy.options[:offset] = value.to_i
      copy
    end

    def search_limit
      @options[:limit]
    end

    def limit(value)
      copy = clone
      copy.options[:limit] = value.to_i
      copy
    end

    def max_matches
      @options[:max_matches] # FIXME try to get actual value from index_options
    end

    def populated?
      !!@populated
    end

    def to_a
      populate
      @array
    end

    def results
      populate
      @results
    end

    def client
      cli = config.client
      cli.max_matches = max_matches   if max_matches
      cli.offset      = search_offset if search_offset
      cli.limit       = search_limit  if search_limit
      cli.match_mode  = match_mode
      cli.filters     = internal_filters + filters
      cli.sort_mode   = sort_mode
      cli.sort_by     = sort_by.join(', ') unless sort_by.empty?
      cli
    end

    def clone
      copy = self.class.new(@args, @options).apply(self)
    end

    def ==(other)
      query      == other.query &&
      options    == other.options &&
      filters    == other.filters &&
      classes    == other.classes &&
      conditions == other.conditions &&
      match_mode == other.match_mode &&
      sort_mode  == other.sort_mode &&
      sort_by    == other.sort_by
    end

    protected

    attr_reader :options, :filters, :conditions, :classes, :sort_by

    attr_reader :_match_mode
    attr_reader :_sort_mode

    def apply(object)
      return unless self.class === object
      @filters.concat object.filters
      @classes.concat object.classes
      @sort_by.concat object.sort_by
      @conditions  << object.conditions
      @_match_mode  = object._match_mode
      @_sort_mode   = object._sort_mode
      self
    end

    # based on:
    # ThinkingSphinx::Search#conditions_as_query
    def apply_conditions(conditions = {})
      if Hash === conditions
        keys = conditions.keys.reject { |key| attributes.include?(key) }
        @conditions << SEPARATOR
        @conditions << keys.collect { |key| "@#{key} #{conditions[key]}" }.join(SEPARATOR)
      else
        @conditions << SEPARATOR
        @conditions << conditions.to_s
      end
      @_match_mode = :extended
      self
    end

    # based on:
    # ThinkingSphinx::Search#condition_filters
    def apply_filters(exclude, options = {})
      options.each do |a,value|
        if attributes.include?(a.to_sym) && !has_filter?(a.to_s, v = filter_value(value), exclude)
          filter = Riddle::Client::Filter.new(a.to_s, v, exclude)
          @filters << filter
        end
      end
      self
    end

    def apply_order(value)
      @_sort_mode = case value
      when String
        :extended
      when Symbol
        :attr_asc
      else
        :relevance
      end
      @sort_by << value.to_s
      self
    end

    def apply_options(value = {})
      @options ||= {}
      value.each do |k,v|
        case k
        when :with
          apply_filters(false, v)
        when :without
          apply_filters(true, v)
        when :conditions
          apply_conditions(v)
        when :order
          apply_order(v)
        when :classes
          @classes = Array(v)
        when :offset, :limit
          @options[k] = v.to_i
        else
          @options[k] = v
        end
      end
      self
    end

    private

    def populate
      return if populated?
      @populated = true
      @results = client.query(query, indexes)
      @array = (@options[:ids_only] ? document_ids : documents)
    rescue Errno::ECONNREFUSED => exception
      raise
    end

    def document_ids
      results[:matches].map { |thing| thing[:doc] }
    end

    def documents
      results[:matches].map { |thing| document(thing) }
    end

    def document(thing)
      klass = config.class_from_crc(thing[:attributes]['xmlpipes_class_crc'].to_i)
      klass.from_document_id(thing[:doc].to_i)
    end

    def attributes
      @attributes ||= @classes.collect { |klass| 
        klass.sphinx_pipes.collect { |i| i.attributes.map { |a| a.name }}
      }.flatten
    end

    def indexes
      @indexes ||= begin
        @classes.empty? ? '*' :
        @classes.collect { |klass| klass.sphinx_pipes.collect { |i| i.names } }.join(',')
      end
    end

    def has_filter?(a,v,e)
      @filters.any? { |f| f.attribute == a && f.values == v && f.exclude == e }
    end

    def internal_filters
      @internal_filters ||= begin
        internal = []
        class_crcs = @classes.map { |klass| Utils.crc32(klass) }
        unless class_crcs.empty?
          internal << Riddle::Client::Filter.new('xmlpipes_class_crc', class_crcs)
        end
        internal
      end
    end

    # source:
    # ThinkingSphinx::Search#filter_value
    def filter_value(value)
      case value
      when Range
        filter_value(value.first).first..filter_value(value.last).first
      when Array
        value.collect { |v| filter_value(v) }.flatten
      when Time
        [value.to_i]
      when NilClass
        0
      else
        Array(value)
      end
    end

    # source:
    # ThinkingSphinx::Search#star_query
    def star_query(value)
      token = @options[:star].is_a?(Regexp) ? @options[:star] : /\w+/u

      value.gsub(/("#{token}(.*?#{token})?"|(?![!-])#{token})/u) do
        pre, proper, post = $`, $&, $'
        # E.g. "@foo", "/2", "~3", but not as part of a token
        is_operator = pre.match(%r{(\W|^)[@~/]\Z})
        # E.g. "foo bar", with quotes
        #
        is_quote    = proper.start_with?('"') && proper.end_with?('"')
        has_star    = pre.end_with?("*") || post.start_with?("*")
        if is_operator || is_quote || has_star
          proper
        else
          "*#{proper}*"
        end
      end
    end

    def config
      XMLPipes::Configuration.instance
    end

  end
end