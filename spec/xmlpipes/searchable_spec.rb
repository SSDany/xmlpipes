require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Searchable do

  before(:each) do
    @class = Class.new { extend XMLPipes::Searchable }
  end

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

  it 'provides the #search method' do
    @class.should respond_to(:search)
  end

  describe '#search' do

    it 'returns a new instance of the XMLPipes::Search' do
      @class.search('Misaki').should be_an_instance_of XMLPipes::Search
    end

    it 'passes proper class to the XMLPipes::Search.new' do
      @class.search('Misaki').send(:classes).should == [@class]
    end

  end

end