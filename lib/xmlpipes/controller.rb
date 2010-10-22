module XMLPipes #:nodoc:
  class Controller < Riddle::Controller

    #--
    # http://sphinxsearch.com/docs/current.html#ref-indexer
    #
    # --merge-dst-range <attr> <min> <max> runs the filter range given upon merging.
    # Specifically, as the merge is applied to the destination index
    # (as part of --merge, and is ignored if --merge is not specified),
    # indexer will also filter the documents ending up in the destination index,
    # and only documents will pass through the filter given will end up in the final index.
    # This could be used for example, in an index where there is a 'deleted' attribute,
    # where 0 means 'not deleted'. Such an index could be merged with: 
    #
    # $ indexer --merge main delta --merge-dst-range deleted 0 0
    #
    # Any documents marked as deleted (value 1) would be removed from the newly-merged destination index.
    # It can be added several times to the command line, to add successive filters to the merge,
    # all of which must be met in order for a document to become part of the final index. 
    #++

    def merge(dst, src, options = {})

      cmd = "#{indexer} --config \"#{@path}\" --merge #{dst} #{src}"
      cmd << " --rotate" if running?

      if ranges = options[:ranges]
        ranges.each do |a, range|
          case range
          when Range
            cmd << " --merge-dst-range #{a} #{range.first} #{range.last}" unless range.exclude_end? # 0...0.12 - step?
          when Array
            cmd << " --merge-dst-range #{a} #{range.min} #{range.max}"
          end
        end
      end

      options[:verbose] ? system(cmd) : `#{cmd}`
    end

  end
end