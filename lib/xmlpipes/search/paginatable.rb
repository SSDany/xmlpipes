module XMLPipes #:nodoc:
  class Search #:nodoc:

    # based on:
    # ThinkingSphinx::Search
    class Paginated

      def initialize(search, options = {})
        @search = search
        @options = options
      end

      def offset
        (current_page - 1) * per_page
      end

      def next_page
        current_page >= total_pages ? nil : current_page + 1
      end

      def previous_page
        current_page == 1 ? nil : current_page - 1
      end

      def current_page
        @options[:page] ? @options[:page].to_i : 1
      end

      def total_entries
        return 0 if results[:total_found].nil?
        @total_entries ||= results[:total_found]
      end

      def total_pages
        return 0 if results[:total].nil?
        @total_pages ||= (results[:total] / per_page.to_f).ceil
      end

      def per_page
        @options[:per_page] ? @options[:per_page].to_i : 20
      end

      include Documentable

      attr_reader :search

      def config
        @search.config
      end

      private :config

      def results
        @search.results
      end

    end

    module Paginatable

      # just wraps a copy of self into the Search::Paginated,
      # so the #paginate is definitely the endpoint.
      def paginate(options = {})
        copy = clone
        paginated = XMLPipes::Search::Paginated.new(copy, options)
        copy.apply_options :limit => paginated.per_page, :offset => paginated.offset
        paginated
      end

    end

    include Paginatable

  end
end