require File.expand_path File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe XMLPipes::Search do

  describe '#clone' do

    it 'returns a new instance of the XMLPipes::Search' do
      @search = XMLPipes::Search.new('Misaki')
      copy = @search.clone
      copy.should == @search
      copy.should_not be_eql @search
    end

  end

  # source:
  # thinking_sphinx/search_spec.rb

  describe '#query' do

    it 'concatenates arguments with spaces' do
      search = XMLPipes::Search.new('NHK', 'Misaki')
      search.query.should == 'NHK Misaki'
    end

    it 'applies stars if requested, and handles full extended syntax' do
      query    = %{a b* c (d | e) 123 5&6 (f_f g) !h "i j" "k l"~10 "m n"/3 @o p -(q|r)}
      expected = %{*a* b* *c* (*d* | *e*) *123* *5*&*6* (*f_f* *g*) !*h* "i j" "k l"~10 "m n"/3 @o *p* -(*q*|*r*)}

      search = XMLPipes::Search.new(query, :star => true)
      search.query.should == expected
    end

    it 'should defaults to /\w+/ as token for auto-starring' do
      search = XMLPipes::Search.new('foo@bar.com', :star => true)
      search.query.should == '*foo*@*bar*.*com*'
    end

    it 'honours custom star tokens' do
      search = XMLPipes::Search.new('foo@bar.com -foo-bar', :star => /[\w@.-]+/u)
      search.query.should == '*foo@bar.com* -*foo-bar*'
    end

    it 'appends conditions to the query' do
      search = XMLPipes::Search.new('Misaki', :conditions => {:title => 'NHK'})
      search.query.should == 'Misaki @title NHK'
    end

    it 'concatenates multiple conditions together' do
      search = XMLPipes::Search.new('Misaki', :conditions => {:title => 'NHK', :description => 'hikikomori'})
      query = search.query
      query.should =~ %r{@title NHK}
      query.should =~ %r{@description hikikomori}
    end

  end

  describe '#match_mode' do

    it 'uses :all by default' do
      search = XMLPipes::Search.new('Misaki')
      search.client.match_mode.should == :all
    end

    it 'defaults to :extended when some conditions supplied' do
      search = XMLPipes::Search.new('Misaki').where(:title => 'NHK')
      search.client.match_mode.should == :extended
    end

    it 'uses explicit match_mode, if any' do
      search = XMLPipes::Search.new('Nakahara Misaki', :match_mode => :phrase)
      search.client.match_mode.should == :phrase
      search = XMLPipes::Search.new('Nakahara Misaki', :match_mode => :phrase).where(:title => 'NHK')
      search.client.match_mode.should == :phrase
    end

  end

  describe '#sort_mode' do

    it 'uses :relevance by default' do
      search = XMLPipes::Search.new('Misaki')
      search.client.sort_mode.should == :relevance
    end

    it 'uses :attr_asc if a symbol is supplied to :order' do
      search = XMLPipes::Search.new('Misaki', :order => :volumes)
      search.client.sort_mode.should == :attr_asc
    end

    it 'uses :attr_desc if :desc is the mode' do
      search = XMLPipes::Search.new('Misaki', :order => :volumes, :sort_mode => :desc)
      search.client.sort_mode.should == :attr_desc
    end

    it 'uses :extended if a string is supplied to :order' do
      search = XMLPipes::Search.new('Misaki', :order => 'volumes ASC')
      search.client.sort_mode.should == :extended
    end

    it 'uses :expr if explicitly requested' do
      search = XMLPipes::Search.new('Misaki', :order => 'volumes ASC', :sort_mode => :expr)
      search.client.sort_mode.should == :expr
    end

    it 'uses :attr_desc if explicitly requested' do
      search = XMLPipes::Search.new('Misaki', :order => 'volumes', :sort_mode => :desc)
      search.client.sort_mode.should == :attr_desc
    end

  end

  describe '#with' do

    before(:each) do
      @search = XMLPipes::Search.new('Misaki', :classes => Article)
    end

    it 'returns a copy of self' do
      scoped = @search.with(:deleted => false)
      scoped.should be_an_instance_of XMLPipes::Search
      scoped.should_not be_eql @search
    end

    it 'is able to apply the inclusive filters of booleans' do
      scoped = @search.with(:deleted => false)
      filter = scoped.client.filters.last
      filter.values.should == [false]
      filter.attribute.should == 'deleted'
      filter.should_not be_exclude
    end

    it 'is able to apply the inclusive filters of Integers' do
      scoped = @search.with(:comments_count => 5)
      filter = scoped.client.filters.last
      filter.values.should == [5]
      filter.attribute.should == 'comments_count'
      filter.should_not be_exclude
    end

    it 'is able to apply the inclusive filters of Floats' do
      scoped = @search.with(:rating => 12.00)
      filter = scoped.client.filters.last
      filter.values.should == [12.00]
      filter.attribute.should == 'rating'
      filter.should_not be_exclude
    end

    it 'is able to apply the inclusive filters of Ranges' do
      scoped = @search.with(:rating => 12.00..42.00)
      filter = scoped.client.filters.last
      filter.values.should == Range.new(12.00,42.00)
      filter.attribute.should == 'rating'
      filter.should_not be_exclude
    end

    it 'is able to apply the inclusive filters of Arrays' do
      scoped = @search.with(:comments_count => [12,13,14])
      filter = scoped.client.filters.last
      filter.values.should == [12,13,14]
      filter.attribute.should == 'comments_count'
      filter.should_not be_exclude
    end

    it 'treats nils in arrays as 0' do
      scoped = @search.with(:comments_count => [nil,12,13,14])
      filter = scoped.client.filters.last
      filter.values.should == [0,12,13,14]
    end

    it 'is able to apply the inclusive filters of time ranges' do
      last = Time.now
      first = last - 3600 * 24 * 7
      scoped = @search.with(:created_at => first..last)
      filter = scoped.client.filters.last
      filter.values.should    == Range.new(first.to_i,last.to_i)
      filter.attribute.should == 'created_at'
      filter.should_not be_exclude
    end

  end

  describe '#without' do

    before(:each) do
      @search = XMLPipes::Search.new('Misaki', :classes => Article)
    end

    it 'creates a copy of self' do
      scoped = @search.without(:deleted => true)
      scoped.should be_an_instance_of XMLPipes::Search
      scoped.should_not be_eql @search
    end

    it 'is able to apply the exclusive filters of booleans' do
      scoped = @search.without(:deleted => false)
      filter = scoped.client.filters.last
      filter.values.should == [false]
      filter.attribute.should == 'deleted'
      filter.should be_exclude
    end

    it 'is able to apply the exclusive filters of Integers' do
      scoped = @search.without(:comments_count => 5)
      filter = scoped.client.filters.last
      filter.values.should == [5]
      filter.attribute.should == 'comments_count'
      filter.should be_exclude
    end

    it 'is able to apply the exclusive filters of Floats' do
      scoped = @search.without(:rating => 12.00)
      filter = scoped.client.filters.last
      filter.values.should == [12.00]
      filter.attribute.should == 'rating'
      filter.should be_exclude
    end

    it 'is able to apply the exclusive filters of Ranges' do
      scoped = @search.without(:rating => 12.00..42.00)
      filter = scoped.client.filters.last
      filter.values.should == Range.new(12.00,42.00)
      filter.attribute.should == 'rating'
      filter.should be_exclude
    end

    it 'is able to apply the exclusive filters of Arrays' do
      scoped = @search.without(:comments_count => [12,13,14])
      filter = scoped.client.filters.last
      filter.values.should == [12,13,14]
      filter.attribute.should == 'comments_count'
      filter.should be_exclude
    end

    it 'treats nils in arrays as 0' do
      scoped = @search.without(:comments_count => [nil,12,13,14])
      filter = scoped.client.filters.last
      filter.values.should == [0,12,13,14]
    end

    it 'is able to apply the exclusive filters of time ranges' do
      last = Time.now
      first = last - 3600 * 24 * 7
      scoped = @search.without(:created_at => first..last)
      filter = scoped.client.filters.last
      filter.values.should    == Range.new(first.to_i,last.to_i)
      filter.attribute.should == 'created_at'
      filter.should be_exclude
    end

  end

  describe '#apply_filters' do

    before(:each) do
      @search = XMLPipes::Search.new('Misaki', :classes => Book)
    end

    it 'does not create a new filter when called with an empty Hash' do
      Riddle::Client::Filter.should_not_receive(:new)
      scoped = @search.send(:apply_filters, false, {})
      scoped.should be_eql @search
    end

    it 'ignores unknown attributes' do
      Riddle::Client::Filter.should_not_receive(:new)
      scoped = @search.send(:apply_filters, false, :bogus => true)
      scoped.should be_eql @search
    end

    it 'does not create a new filter when same filter is already applied' do
      @search.send(:apply_filters, false, :deleted => false)
      Riddle::Client::Filter.should_not_receive(:new)
      @search.send(:apply_filters, false, :deleted => false)
    end

  end

  describe '#where' do

    before(:each) do
      @search = XMLPipes::Search.new('Misaki')
    end

    it 'creates a copy of self' do
      scoped = @search.without(:deleted => true)
      scoped.should be_an_instance_of XMLPipes::Search
      scoped.should_not be_eql @search
    end

    it 'appends conditions to the query' do
      search = XMLPipes::Search.new('Misaki', :conditions => {:title => 'NHK'})
      search.query.should == 'Misaki @title NHK'
    end

    it 'concatenates multiple conditions together' do
      search = XMLPipes::Search.new('Misaki', :conditions => {:title => 'NHK', :description => 'hikikomori'})
      query = search.query
      query.should =~ %r{@title NHK}
      query.should =~ %r{@description hikikomori}
    end

  end

  it 'allows to specify the order explicitly' do
    search = XMLPipes::Search.new('Misaki', :order => 'volumes ASC')
    search.client.sort_by.should == 'volumes ASC'
  end

  it 'and presumes order symbols are attributes' do
    search = XMLPipes::Search.new('Misaki', :order => :volumes)
    search.client.sort_by.should == 'volumes'
  end

  describe '#order' do

    it 'creates a copy of self' do
      search = XMLPipes::Search.new('Misaki')
      scoped = search.order('volumes ASC')
      scoped.should_not be_equal search
      scoped.client.sort_by.should == 'volumes ASC'
    end

    it 'concatenates ordering' do
      search = XMLPipes::Search.new('Misaki', :order => 'rating DESC')
      scoped = search.order('volumes ASC')
      scoped.client.sort_by.should == 'rating DESC, volumes ASC'
    end

  end

  it 'allows to specify the limit explicitly' do
    search = XMLPipes::Search.new('Misaki', :limit => 10)
    search.client.limit.should == 10
  end

  describe '#limit' do

    it 'creates a copy of self' do
      search = XMLPipes::Search.new('Misaki')
      scoped = search.limit(5)
      scoped.should_not be_equal search
      scoped.client.limit.should == 5
    end

    it 'overrides previuosly defined limit' do
      search = XMLPipes::Search.new('Misaki', :limit => 10)
      scoped = search.limit(5)
      scoped.client.limit.should == 5
    end

  end

  it 'allows to specify the offset explicitly' do
    search = XMLPipes::Search.new('Misaki', :offset => 10)
    search.client.offset.should == 10
  end

  describe '#offset' do

    it 'creates a copy of self' do
      search = XMLPipes::Search.new('Misaki')
      scoped = search.offset(5)
      scoped.should_not be_equal search
      scoped.client.offset.should == 5
    end

    it 'overrides previuosly defined offset' do
      search = XMLPipes::Search.new('Misaki', :offset => 10)
      scoped = search.offset(5)
      scoped.client.offset.should == 5
    end

  end

  describe '#indexes' do

    it 'uses requested classes to generate the list of indexes' do
      search = XMLPipes::Search.new('Misaki', :classes => [Book, Article])
      search.send(:indexes).should == 'titles_core,books_core,books_delta,articles_core,articles_delta'
    end

    it 'uses "*" otherwise' do
      search = XMLPipes::Search.new('Misaki')
      search.send(:indexes).should == '*'
    end

  end

  describe '#populated?' do

    before(:each) do
      @search = XMLPipes::Search.new('Misaki')
    end

    it 'returns false if the client request has not been made' do
      @search.should_not be_populated
    end

    it 'returns true otherwise' do
      @search.should_receive(:client).and_return(mock(:client, :query => {:matches => []}))
      @search.to_a
      @search.should be_populated
    end

  end

end