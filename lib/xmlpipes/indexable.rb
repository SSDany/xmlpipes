module XMLPipes #:nodoc:
  module Indexable

    def define_pipes(name,&block)
      index = Index.new(name,self)
      yield(index) if block_given?
      Configuration.instance.indexed(self)
      sphinx_pipes.reject! { |i| i.name == index.name }
      sphinx_pipes << index
    end

    def to_riddle
      indexes = []
      sphinx_pipes.each { |index| indexes.concat index.to_riddle }
      indexes
    end

    def sphinx_pipes
      @sphinx_pipes ||= []
    end

    def has_sphinx_pipes?
      !sphinx_pipes.empty?
    end

    def indexer
      @indexer ||= XMLPipes::Indexer.new(self)
    end

  end
end