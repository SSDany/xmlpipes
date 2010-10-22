require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Indexer do

  before(:all) do
    @temporary = SPEC_ROOT.join('fixtures/tmp/testing')
    XMLPipes::Configuration.configure do |config| 
      config.root = SPEC_ROOT.join('fixtures')
      config.environment = 'testing'
    end

    FileUtils.mkdir_p(@temporary)
    Dir.stub!(:tmpdir).and_return(@temporary)
  end

  describe '#index' do

    before(:each) do
      @controller = mock(:controller)
      Book.indexer.stub!(:controller).and_return(@controller)
    end

    it 'does nothing when called with unknown index' do
      @controller.should_not_receive(:index)
      Book.indexer.index(:bogus)
    end

    describe 'without deltas' do

      it 'attempts to (re)index core' do
        @controller.should_receive(:index).with('titles_core', anything())
        Book.indexer.index(:titles)
      end

      it 'passes options to the controller' do
        @controller.should_receive(:index).with(anything(), :verbose => true)
        Book.indexer.index(:titles, :verbose => true)
      end

    end

    describe 'with deltas' do

      it 'attempts to (re)index delta and core' do
        @controller.should_receive(:index).with('books_core', anything())
        @controller.should_receive(:index).with('books_delta', anything())
        Book.indexer.index(:books)
      end

      it 'passes options to the controller' do
        @controller.should_receive(:index).with(anything(), :verbose => true).twice
        Book.indexer.index(:books, :verbose => true)
      end

    end

  end

  describe '#update' do

    before(:each) do
      @index = Book.sphinx_pipes.detect { |i| i.name == :books }
      @client = mock(:client)
      Book.indexer.stub!(:client).and_return(@client)
    end

    it 'does nothing when called with unknown index' do
      @client.should_not_receive(:update)
      Book.indexer.update(:bogus, 42, :deleted => true)
    end

    it 'does nothing when docinfo of the index is not "extern"' do
      @index.stub!(:docinfo).and_return('NOT extern')
      @client.should_not_receive(:update)
      Book.indexer.update(:books, 42, :deleted => true)
    end

    it 'ignores unknown attributes' do
      @client.should_not_receive(:update)
      Book.indexer.update(:books, 42, :bogus => true)
    end

    it 'attempts to update attributes otherwise' do
      @client.should_receive(:update).with('books', ['deleted'], {44=>[1], 42=>[1], 43=>[1]}).once
      Book.indexer.update(:books, [42, 43, 44], :deleted => true)
    end

  end

  describe '#merge' do

    before(:each) do
      @controller = mock(:controller)
      Book.indexer.stub!(:controller).and_return(@controller)
    end

    it 'does nothing when called with unknown index' do
      @controller.should_not_receive(:index)
      @controller.should_not_receive(:merge)
      Book.indexer.merge(:bogus)
    end

    it 'does nothing when deltas has been disabled' do
      @controller.should_not_receive(:index)
      @controller.should_not_receive(:merge)
      Book.indexer.merge(:titles)
    end

    it 'attempts to (re)index delta and merge it into core' do
      @controller.should_receive(:index).with('books_delta', anything).and_return(0)
      @controller.should_receive(:merge).with('books_core', 'books_delta', anything)
      Book.indexer.merge(:books)
    end

    it 'passes options to the controller' do
      options = {:verbose => true, :ranges => {:deleted => [0,0]}}

      @controller.should_receive(:index).with('books_delta', options).and_return(0)
      @controller.should_receive(:merge).with('books_core', 'books_delta', options)
      Book.indexer.merge(:books, :verbose => true, :ranges => {:deleted => [0,0]})
    end

  end

  describe '#core' do

    before(:each) do
      @index = Book.sphinx_pipes.detect { |i| i.name == :books }
    end

    it 'does nothing when called with unknown source' do
      File.should_not_receive(:atomic_write)
      Book.indexer.should_not_receive(:render_documents)
      Book.indexer.core(:bogus)
    end

    it 'uses proper path' do
      source = @index.sources.detect { |s| s.name == :manga }
      File.should_receive(:atomic_write).with(source.core_path)
      Book.indexer.core(:manga)
    end

    it 'uses proper source' do
      source = @index.sources.detect { |s| s.name == :manga }
      Book.indexer.should_receive(:render_documents).with(source).and_return('docset')
      Book.indexer.core(:manga)
    end

    it 'passes documents to the #render_documents' do
      source = @index.sources.detect { |s| s.name == :manga }
      document = YAML.load_file(SPEC_ROOT + 'fixtures/yml/1558914253.yml')
      Book.indexer.should_receive(:render_documents).with(anything, document).and_return('docset')
      Book.indexer.core(:manga, document)
    end

  end

  describe '#delta' do

    before(:each) do
      @index = Book.sphinx_pipes.detect { |i| i.name == :books }
    end

    it 'does nothing when called with unknown source' do
      File.should_not_receive(:atomic_write)
      Book.indexer.should_not_receive(:render_documents)
      Book.indexer.delta(:bogus)
    end

    it 'does nothing when deltas has been disabled' do
      File.should_not_receive(:atomic_write)
      Book.indexer.should_not_receive(:render_documents)
      Book.indexer.delta(:titles)
    end

    it 'uses proper path' do
      source = @index.sources.detect { |s| s.name == :manga }
      File.should_receive(:atomic_write).with(source.delta_path)
      Book.indexer.delta(:manga)
    end

    it 'uses proper source' do
      source = @index.sources.detect { |s| s.name == :manga }
      Book.indexer.should_receive(:render_documents).with(source).and_return('docset')
      Book.indexer.delta(:manga)
    end

    it 'passes documents to the #render_documents' do
      source = @index.sources.detect { |s| s.name == :manga }
      document = YAML.load_file(SPEC_ROOT + 'fixtures/yml/1558914253.yml')
      Book.indexer.should_receive(:render_documents).with(anything, document).and_return('docset')
      Book.indexer.delta(:manga, document)
    end

  end

  describe '#klist' do

    before(:each) do
      @index = Book.sphinx_pipes.detect { |i| i.name == :books }
    end

    it 'does nothing when called with unknown source' do
      File.should_not_receive(:atomic_write)
      Book.indexer.should_not_receive(:render_klist)
      Book.indexer.klist(:bogus)
    end

    it 'does nothing when deltas has been disabled' do
      File.should_not_receive(:atomic_write)
      Book.indexer.should_not_receive(:render_klist)
      Book.indexer.klist(:titles)
    end

    it 'uses proper path' do
      source = @index.sources.detect { |s| s.name == :manga }
      File.should_receive(:atomic_write).with(source.delta_path)
      Book.indexer.klist(:manga)
    end

    it 'uses proper source' do
      source = @index.sources.detect { |s| s.name == :manga }
      Book.indexer.should_receive(:render_klist).with(source).and_return('docset')
      Book.indexer.klist(:manga)
    end

    it 'passes document_ids to the #render_klist' do
      source = @index.sources.detect { |s| s.name == :manga }
      document = YAML.load_file(SPEC_ROOT + 'fixtures/yml/1558914253.yml')
      Book.indexer.should_receive(:render_klist).
      with(anything, 1558914253, 1558914254, 1558914255).and_return('docset')
      Book.indexer.klist(:manga, document, 1558914254, 1558914255)
    end

  end

  describe '#render_documents' do

    before(:each) do
      index = Book.sphinx_pipes.detect { |i| i.name == :books }
      @source = index.sources.detect { |s| s.name == :manga }
      @document = YAML.load_file(SPEC_ROOT + 'fixtures/yml/1558914253.yml')
    end

    it 'uses proper schema' do
      Book.indexer.should_receive(:with_sphinx_schema).with(@source)
      Book.indexer.send(:render_documents, @source, @document)
    end

    it 'builds the sphinx:schema-compatible XML' do
      data = Book.indexer.send(:render_documents, @source, @document)
      docset = Nokogiri::XML.parse(data)

      doc = docset.xpath("//sphinx:docset/sphinx:document[@id=1558914253]")
      doc.should_not be_empty

      doc.xpath('./title/text()').to_s.should       == 'NHK ni Youkoso!'
      doc.xpath('./description/text()').to_s.should =~ /hikikomori/
      doc.xpath('./authors/text()').to_s.should     == 'Tatsuhiko Takimoto'
      doc.xpath('./publisher/text()').to_s.should   == 'Kadokawa Shoten'
      doc.xpath('./tags/text()').to_s.should        == '1558914253,2552549528,1985650179'
      doc.xpath('./volumes/text()').to_s.should     == '8'
      doc.xpath('./deleted').should be_empty
    end

  end

  describe '#render_klist' do

    before(:each) do
      index = Book.sphinx_pipes.detect { |i| i.name == :books }
      @source = index.sources.detect { |s| s.name == :manga }
    end

    it 'uses proper schema' do
      Book.indexer.should_receive(:with_sphinx_schema).with(@source)
      Book.indexer.send(:render_klist, @source, 1558914253, 1558914254, 1558914255)
    end

    it 'builds the sphinx:schema-compatible XML' do
      data = Book.indexer.send(:render_klist, @source, 1558914253, 1558914254, 1558914255)
      docset = Nokogiri::XML.parse(data)
      document_ids = docset.xpath('//sphinx:docset/sphinx:killlist/id/text()').map { |doc| doc.to_s.to_i }

      document_ids.size.should == 3
      document_ids[0].should == 1558914253
      document_ids[1].should == 1558914254
      document_ids[2].should == 1558914255
    end

  end

  describe '#with_sphinx_schema' do

    before(:each) do
      index   = Book.sphinx_pipes.detect { |i| i.name == :books }
      source  = index.sources.detect { |s| s.name == :manga }
      data    = Book.indexer.send(:with_sphinx_schema, source)
      @schema = Nokogiri::XML.parse(data).at('//sphinx:docset/sphinx:schema')
    end

    it 'uses proper fields' do
      @schema.xpath('count(sphinx:field)').should == 4
      @schema.xpath('sphinx:field[1]/@name').to_s.should == 'title'
      @schema.xpath('sphinx:field[2]/@name').to_s.should == 'description'
      @schema.xpath('sphinx:field[3]/@name').to_s.should == 'authors'
      @schema.xpath('sphinx:field[4]/@name').to_s.should == 'publisher'
    end

    it 'uses proper attributes' do
      @schema.xpath('count(sphinx:attr)').should == 3

      @schema.xpath('count(sphinx:attr[1]/@*)').should == 3
      @schema.xpath('sphinx:attr[1]/@name').to_s.should == 'tags'
      @schema.xpath('sphinx:attr[1]/@type').to_s.should == 'multi'
      @schema.xpath('sphinx:attr[1]/@default').to_s.should == 'manga'

      @schema.xpath('count(sphinx:attr[2]/@*)').should == 4
      @schema.xpath('sphinx:attr[2]/@name').to_s.should == 'volumes'
      @schema.xpath('sphinx:attr[2]/@type').to_s.should == 'int'
      @schema.xpath('sphinx:attr[2]/@bits').to_s.should == '8'
      @schema.xpath('sphinx:attr[2]/@default').to_s.should == '1'

      @schema.xpath('count(sphinx:attr[3]/@*)').should == 3
      @schema.xpath('sphinx:attr[3]/@name').to_s.should == 'deleted'
      @schema.xpath('sphinx:attr[3]/@type').to_s.should == 'bool'
      @schema.xpath('sphinx:attr[3]/@default').to_s.should == '0'
    end

  end

  after(:all) do
    XMLPipes::Configuration.instance.reset
    FileUtils.rm_rf(@temporary)
  end

end