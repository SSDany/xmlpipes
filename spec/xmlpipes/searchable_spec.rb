require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Searchable do

  before(:each) do
    @class = Class.new { extend XMLPipes::Searchable }
  end

  describe 'when included into the model' do

    it 'provides the #from_document_id method' do
      @class.should respond_to(:from_document_id)
    end

    it 'which raises a NotImplementedError, unfortunately' do
      lambda { @class.from_document_id(42) }.
      should raise_error NotImplementedError, %r{XMLPipes::Searchable}
    end

    it 'and it does not override an existing #from_document_id method' do
      klass = Class.new { def self.from_document_id(doc); doc; end }
      klass.from_document_id(42).should == 42
      klass.extend XMLPipes::Searchable
      lambda { klass.from_document_id(42) }.should_not raise_error
      klass.from_document_id(42).should == 42
    end

  end

  it 'provides the #search method' do
    @class.should respond_to(:search)
  end

  it 'provides the #search_for_ids method' do
    @class.should respond_to(:search_for_ids)
  end

  describe '#search' do

    it 'returns a new instance of the XMLPipes::Search' do
      @class.search('Misaki').should be_an_instance_of XMLPipes::Search
    end

    it 'passes proper class to the XMLPipes::Search.new' do
      XMLPipes::Search.should_receive(:new).with('Misaki', hash_including(:classes => [@class]))
      @class.search('Misaki')
    end

    it 'passes proper options to the XMLPipes::Search.new' do
      XMLPipes::Search.should_receive(:new).with('Misaki', hash_including(:ids_only => false))
      @class.search('Misaki')
    end

  end

  describe '#search_for_ids' do

    it 'returns a new instance of the XMLPipes::Search' do
      @class.search_for_ids('Misaki').should be_an_instance_of XMLPipes::Search
    end

    it 'passes proper class to the XMLPipes::Search.new' do
      XMLPipes::Search.should_receive(:new).with('Misaki', hash_including(:classes => [@class]))
      @class.search_for_ids('Misaki')
    end

    it 'passes proper options to the XMLPipes::Search.new' do
      XMLPipes::Search.should_receive(:new).with('Misaki', hash_including(:ids_only => true))
      @class.search_for_ids('Misaki')
    end

  end

end