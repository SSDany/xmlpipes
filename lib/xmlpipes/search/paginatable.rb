module XMLPipes #:nodoc:
  class Search #:nodoc:

    class Paginated

      attr_reader :per_page
      attr_reader :current_page

      def initialize(search, options = {})
        @array        = []
        @search       = search
        @current_page = options[:page] ? options[:page].to_i : 1
        @per_page     = options[:per_page] ? options[:per_page].to_i : 20

        @search.send(:apply_options, :limit => per_page, :offset => offset)
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

      def total_entries
        return 0 if results[:total_found].nil?
        @total_entries ||= results[:total_found]
      end

      def total_pages
        return 0 if results[:total].nil?
        @total_pages ||= (results[:total] / per_page.to_f).ceil
      end

      def out_of_bounds?
        current_page > total_pages
      end

      include Documentable

      def to_a
        @array = @search.to_a
      end

      def results
        @search.results
      end

      private

      def config
        @search.config
      end

    end

    module Paginatable

      # just wraps a copy of self into the Search::Paginated,
      # so the #paginate is definitely the endpoint.
      def paginate(options = {})
        XMLPipes::Search::Paginated.new(clone, options)
      end

    end

    include Paginatable

  end
end