module XMLPipes #:nodoc:
  class Collection

    CoreMethods = %w(== class class_eval eql? equal? extend frozen? id instance_eval
      instance_of? instance_values instance_variable_defined?
      instance_variable_get instance_variable_set instance_variables is_a?
      kind_of? member? method methods nil? object_id respond_to? send should should_not
      type)

    self.instance_methods.each { |method_id|
      next if method_id.to_s[/^__/] || CoreMethods.include?(method_id.to_s)
      undef_method method_id
    }

    def initialize
      @array = []
    end

    def method_missing(method_id, *args, &block)
      if @array.respond_to?(method_id)
        self.class.class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def #{method_id}(*args, &block); self.to_a.#{method_id}(*args,&block); end
        METHOD
        send(method_id, *args, &block)
      else
        raise NoMethodError # TODO: message
      end
    end

    def to_a
      raise NotImplementedError
    end

    def respond_to?(*args)
      super || @array.respond_to?(*args)
    end

  end
end