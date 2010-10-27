require File.expand_path File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

require 'xmlpipes/search/paginatable.rb'

describe XMLPipes::Search::Paginatable do

  describe '#paginate' do

    it 'returns an instance of the XMLPipes::Search::Paginated' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 30)
      paginated.should be_an_instance_of XMLPipes::Search::Paginated
    end

    it 'uses a per_page value as a limit' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 30)
      paginated.search.client.limit.should == 30
    end

    it 'defaults limit to 20' do
      paginated = XMLPipes::Search.new('Misaki').paginate()
      paginated.search.client.limit.should == 20
    end

    it 'calculates the offset using page and per_page values' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:page => 3, :per_page => 30)
      paginated.search.client.offset.should == 60
    end

    it 'is able to calculate the offset using the page value only' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:page => 3)
      paginated.search.client.offset.should == 40
    end

  end

end

describe XMLPipes::Search::Paginated do

  describe '#total_entries' do

    it 'returns 0 if nothing was found' do
      paginated = XMLPipes::Search.new('Misaki').paginate
      paginated.search.stub!(:results).and_return({})
      paginated.total_entries.should == 0
    end

    it 'returns the number of results found otherwise' do
      paginated = XMLPipes::Search.new('Misaki').paginate
      paginated.search.stub!(:results).and_return(:total_found => 144)
      paginated.total_entries.should == 144
    end

  end

  describe '#total_pages' do

    it 'returns 0 if nothing was found' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10)
      paginated.search.stub!(:results).and_return({})
      paginated.total_pages.should == 0
    end

    it 'returns the number of pages otherwise' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10)
      paginated.search.stub!(:results).and_return(:total => 120)
      paginated.total_pages.should == 12
    end

  end

  describe '#current_page' do

    it 'uses the page value as a current page' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:page => 2)
      paginated.current_page.should == 2
    end

    it 'defaults the current page to 1' do
      paginated = XMLPipes::Search.new('Misaki').paginate
      paginated.current_page.should == 1
    end

  end

  describe '#next_page' do

    it 'returns nil if nothing was found' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10, :page => 2)
      paginated.search.stub!(:results).and_return({})
      paginated.next_page.should be_nil
    end

    it 'returns nil when there is no next page' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10, :page => 2)
      paginated.search.stub!(:results).and_return(:total => 20)
      paginated.next_page.should be_nil
    end

    it 'returns the next page value otherwise' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10, :page => 2)
      paginated.search.stub!(:results).and_return(:total => 30)
      paginated.next_page.should == 3
    end

  end

  describe '#previous_page' do

    it 'returns nil when current page is 1' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10, :page => 1)
      paginated.previous_page.should be_nil
    end

    it 'returns the previous page value otherwise' do
      paginated = XMLPipes::Search.new('Misaki').paginate(:per_page => 10, :page => 2)
      paginated.previous_page.should == 1
    end

  end

end