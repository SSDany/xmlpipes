module XMLPipes #:nodoc:
  module Strategies #:nodoc:
    module Simple

      def update_attributes(*args)
        indexer.update(sphinx_index, *args)
      end

      def clean(options = {})
        indexer.core(sphinx_source)
        indexer.delta(sphinx_source)
        indexer.index(sphinx_index, options)
      end

      def index(*args, &block)
        options = Hash === args.last ? args.pop : {}
        indexer.core(sphinx_source, *args.flatten, &block)
        indexer.delta(sphinx_source)
        indexer.index(sphinx_index, options)
      end

      alias :reindex :index

      def merge(*args, &block)
        options = Hash === args.last ? args.pop : {}
        indexer.delta(sphinx_source, *args.flatten, &block)
        indexer.merge(sphinx_index, options)
      end

      def kill(*args)
        options = Hash === args.last ? args.pop : {}
        indexer.klist(sphinx_source, *args.flatten)
        indexer.merge(sphinx_index, options)
      end

      private

      def sphinx_source
        @sphinx_source ||= sphinx_index.sources.first
      end

      def sphinx_index
        @sphinx_index ||= sphinx_pipes.first
      end

    end
  end
end