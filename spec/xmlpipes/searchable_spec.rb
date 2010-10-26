require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Searchable do

  before(:each) do
    @class = Class.new { extend XMLPipes::Searchable }
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