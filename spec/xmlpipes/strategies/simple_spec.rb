require 'xmlpipes/strategies/simple.rb'

describe XMLPipes::Strategies::Simple do

  before(:all) do
    @index  = Article.sphinx_pipes.first
    @source = @index.sources.first
  end

  before(:each) do
    Article.stub!(:indexer).and_return(@indexer = mock(:indexer))
  end

  describe '#update_attributes' do
    it 'attempts to update attributes' do
      @indexer.should_receive(:update).with(@index, 42, 43, 44, :deleted => true)
      Article.update_attributes(42, 43, 44, :deleted => true)
    end
  end

  describe '#clean' do
    it 'attempts to cleanup core and delta indexes' do
      @indexer.should_receive(:core).with(@source).ordered
      @indexer.should_receive(:delta).with(@source).ordered
      @indexer.should_receive(:index).with(@index, :verbose => true).ordered
      Article.clean(:verbose => true)
    end
  end

  describe '#index' do
    it 'attempts to create a core-index (using resources passed) ' \
       'and an empty delta-index' do
      @indexer.should_receive(:core).with(@source, 42, 43, 44).ordered
      @indexer.should_receive(:delta).with(@source).ordered
      @indexer.should_receive(:index).with(@index, :verbose => true).ordered
      Article.index(42, 43, 44, :verbose => true)
    end
  end

  describe '#merge' do
    it 'attempts to reindex delta (using resources passed) ' \
       'and then merge delta-index into the core' do
      @indexer.should_receive(:delta).with(@source, 42, 43, 44).ordered
      @indexer.should_receive(:merge).with(@index, :verbose => true).ordered
      Article.merge(42, 43, 44, :verbose => true)
    end
  end

  describe '#kill' do
    it 'attempts to create and apply kill-list(s)' do
      @indexer.should_receive(:klist).with(@source, 42, 43, 44).ordered
      @indexer.should_receive(:merge).with(@index, :verbose => true).ordered
      Article.kill(42, 43, 44, :verbose => true)
    end
  end

end