require 'spec_helper'

describe ActiveNomad::Base do
  describe ".attribute" do
    it "should create a column with the given name and type" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :integer_attribute, :integer
        attribute :string_attribute, :string
        attribute :text_attribute, :text
        attribute :float_attribute, :float
        attribute :decimal_attribute, :decimal
        attribute :datetime_attribute, :datetime
        attribute :timestamp_attribute, :timestamp
        attribute :time_attribute, :time
        attribute :date_attribute, :date
        attribute :binary_attribute, :binary
        attribute :boolean_attribute, :boolean
      end
      klass.columns.should have(11).columns
      klass.columns_hash['integer_attribute'].type.should == :integer
      klass.columns_hash['string_attribute'].type.should == :string
      klass.columns_hash['text_attribute'].type.should == :text
      klass.columns_hash['float_attribute'].type.should == :float
      klass.columns_hash['decimal_attribute'].type.should == :decimal
      klass.columns_hash['datetime_attribute'].type.should == :datetime
      klass.columns_hash['timestamp_attribute'].type.should == :timestamp
      klass.columns_hash['time_attribute'].type.should == :time
      klass.columns_hash['date_attribute'].type.should == :date
      klass.columns_hash['binary_attribute'].type.should == :binary
      klass.columns_hash['boolean_attribute'].type.should == :boolean
    end

    it "should treat a :limit option like #add_column in a migration" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string, :limit => 100
      end
      klass.columns_hash['name'].limit.should == 100
    end

    it "should treat :scale and :precision options like #add_column in a migration" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :value, :decimal, :precision => 5, :scale => 2
      end
      klass.columns_hash['value'].scale.should == 2
      klass.columns_hash['value'].precision.should == 5
    end

    it "should treat a :null option like #add_column in a migration" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :mandatory, :decimal, :null => false
        attribute :optional, :decimal, :null => true
      end
      klass.columns_hash['mandatory'].null.should be_false
      klass.columns_hash['optional'].null.should be_true
    end

    it "should treat a :default option like #add_column in a migration" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string, :default => 'Joe'
      end
      klass.columns_hash['name'].default.should == 'Joe'
    end

    it "should add the attribute to those of any superclasses" do
      superclass = Class.new(ActiveNomad::Base) do
        attribute :a, :integer
      end
      subclass = Class.new(superclass) do
        attribute :b, :integer
      end
      subclass.columns.map{|c| c.name}.should == ['a', 'b']
    end
  end

  describe "an integer attribute" do
    it "should cast the value from a string like ActiveRecord" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :value, :integer
      end
      instance = klass.new(:value => '123')
      instance.value.should == 123
    end
  end

  describe "#save" do
    describe "when no save strategy has been defined" do
      it "should return true" do
        instance = ActiveNomad::Base.new
        instance.save.should be_true
      end
    end

    describe "when a save strategy has been defined" do
      before do
        saves = @saves = []
        @instance = ActiveNomad::Base.new
        @instance.to_save do |*args|
          saves << args
        end
      end

      it "should call the save_proc with the record as an argument" do
        @instance.save
        @saves.should == [[@instance]]
      end
    end

    describe "when #persist has been overridden" do
      before do
        saves = @saves = []
        @klass = Class.new(ActiveNomad::Base) do
          define_method :persist do |*args|
            saves << args
          end
        end
      end

      it "should call it and return the result" do
        instance = @klass.new
        instance.save
        @saves.should == [[]]
      end
    end
  end

  describe "#to_serialized_attributes" do
    it "should return a list of attribute names with serialized attributes, sorted by name" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :integer_attribute, :integer
        attribute :string_attribute, :string
        attribute :text_attribute, :text
        attribute :float_attribute, :float
        attribute :decimal_attribute, :decimal
        attribute :datetime_attribute, :datetime
        attribute :timestamp_attribute, :timestamp
        attribute :time_attribute, :time
        attribute :date_attribute, :date
        attribute :binary_attribute, :binary
        attribute :boolean_attribute, :boolean
        attribute :nil_attribute, :string
      end
      instance = klass.new(
        :integer_attribute => 5,
        :string_attribute => 'string',
        :text_attribute => 'text',
        :float_attribute => 1.23,
        :decimal_attribute => BigDecimal.new('123.45'),
        :datetime_attribute => Time.parse('03 Feb 2001 12:34:56 -0000'),
        :timestamp_attribute => Time.parse('03 Feb 2001 12:34:56 -0000'),
        :time_attribute => Time.parse('03 Feb 2001 12:34:56 -0000'),
        :date_attribute => Date.parse('03 Feb 2001'),
        :binary_attribute => "\0\1",
        :boolean_attribute => true,
        :nil_attribute => nil
      )
      instance.to_serialized_attributes.to_a.should == [
        ['binary_attribute', "\0\1"],
        ['boolean_attribute', 'true'],
        ['date_attribute', '03 Feb 2001'],
        ['datetime_attribute', '03 Feb 2001 12:34:56 -0000'],
        ['decimal_attribute', '123.45'],
        ['float_attribute', '1.23'],
        ['integer_attribute', '5'],
        ['nil_attribute', nil],
        ['string_attribute', 'string'],
        ['text_attribute', 'text'],
        ['time_attribute', '03 Feb 2001 12:34:56 -0000'],
        ['timestamp_attribute', '03 Feb 2001 12:34:56 -0000'],
      ]
    end
  end

  describe ".from_serialized_attributes" do
    it "should create a new record with attributes deserialized from the given parameter list" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :integer_attribute, :integer
        attribute :string_attribute, :string
        attribute :text_attribute, :text
        attribute :float_attribute, :float
        attribute :decimal_attribute, :decimal
        attribute :datetime_attribute, :datetime
        attribute :timestamp_attribute, :timestamp
        attribute :time_attribute, :time
        attribute :date_attribute, :date
        attribute :binary_attribute, :binary
        attribute :boolean_attribute, :boolean
        attribute :nil_attribute, :boolean
      end
      instance = klass.from_serialized_attributes([
        [:integer_attribute, '5'],
        [:string_attribute, 'string'],
        [:text_attribute, 'text'],
        [:float_attribute, '1.23'],
        [:decimal_attribute, '123.45'],
        [:datetime_attribute, '03 Feb 2001 12:34:56 -0000'],
        [:timestamp_attribute, '03 Feb 2001 12:34:56 -0000'],
        [:time_attribute, '03 Feb 2001 12:34:56 -0000'],
        [:date_attribute, '03 Feb 2001'],
        [:binary_attribute, "\0\1"],
        [:boolean_attribute, 'true'],
        [:nil_attribute, nil]
      ])
      instance.integer_attribute.should == 5
      instance.string_attribute.should == 'string'
      instance.text_attribute.should == 'text'
      instance.float_attribute.should == 1.23
      instance.decimal_attribute.should == BigDecimal.new('123.45')
      instance.datetime_attribute.should == Time.parse('03 Feb 2001 12:34:56 -0000')
      instance.timestamp_attribute.should == Time.parse('03 Feb 2001 12:34:56 -0000')
      instance.time_attribute.should == Time.parse('03 Feb 2001 12:34:56 -0000')
      instance.date_attribute.should == Date.parse('03 Feb 2001')
      instance.binary_attribute.should == "\0\1"
      instance.boolean_attribute.should be_true
      instance.nil_attribute.should be_nil
    end

    it "should work with any enumerable" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string
      end
      params = Object.new
      class << params
        def each
          yield :name, 'joe'
        end
      end
      params.extend Enumerable
      instance = klass.from_serialized_attributes(params)
      instance.name.should == 'joe'
    end

    it "should leave defaults alone for attributes which are not set" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string, :default => 'Joe'
      end
      instance = klass.from_serialized_attributes({})
      instance.name.should == 'Joe'
    end
  end

  describe "#to_ordered_query_string" do
    it "should serialize the attributes as a query string" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :first_name, :string
        attribute :last_name, :string
      end
      instance = klass.new(:first_name => 'Joe', :last_name => 'Blow')
      instance.to_ordered_query_string.should == 'first_name=Joe&last_name=Blow'
    end
  end

  describe ".from_query_string" do
    it "should create a new record with no attributes set if nil is given" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string
      end
      instance = klass.from_query_string(nil)
      instance.name.should be_nil
    end

    it "should create a new record with no attributes set if an empty string is given" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string
      end
      instance = klass.from_query_string('')
      instance.name.should be_nil
    end

    it "should create a new record with no attributes set if a blank string is given" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string
      end
      instance = klass.from_query_string(" \t")
      instance.name.should be_nil
    end

    it "should leave defaults alone for attributes which are not set" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string, :default => 'Joe'
      end
      instance = klass.from_query_string(" \t")
      instance.name.should == 'Joe'
    end
  end

  describe ".from_json" do
    it "should not set any attributes if an invalid JSON string is given" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :name, :string
      end
      instance = klass.from_json("invalid")
      instance.name.should be_nil
    end
  end

  def self.it_should_roundtrip_through(serializer, deserializer, &block)
    describe "roundtripping through ##{serializer} and .#{deserializer}" do
      class_eval(&block) if block

      (class << self; self; end).class_eval do
        define_method :it_should_roundtrip do |type, value|
          value = Time.at(value.to_i) if value.is_a?(Time) # chop off subseconds
          it "should roundtrip #{value.inspect} correctly as a #{type}" do
            klass = Class.new(ActiveNomad::Base) do
              attribute :value, type
            end
            instance = klass.new(:value => value)
            roundtripped = klass.send(deserializer, instance.send(serializer))
            roundtripped.value.should == value
          end
        end
      end

      it_should_roundtrip :integer, nil
      it_should_roundtrip :integer, 0
      it_should_roundtrip :integer, 123

      it_should_roundtrip :string, nil
      it_should_roundtrip :string, ''
      it_should_roundtrip :string, 'hi'

      it_should_roundtrip :text, nil
      it_should_roundtrip :text, ''
      it_should_roundtrip :text, 'hi'

      it_should_roundtrip :float, nil
      it_should_roundtrip :float, 0
      it_should_roundtrip :float, 0.123

      it_should_roundtrip :decimal, nil
      it_should_roundtrip :decimal, BigDecimal.new('0')
      it_should_roundtrip :decimal, BigDecimal.new('123.45')

      it_should_roundtrip :datetime, nil
      it_should_roundtrip :datetime, Time.now.in_time_zone
      # TODO: Support DateTime here, which is used when the value is
      # outside the range of a Time.

      it_should_roundtrip :timestamp, nil
      it_should_roundtrip :timestamp, Time.now.in_time_zone

      it_should_roundtrip :time, nil
      it_should_roundtrip :time, Time.parse('2000-01-01 01:23:34').in_time_zone

      it_should_roundtrip :date, nil
      it_should_roundtrip :date, Date.today

      it_should_roundtrip :binary, nil
      it_should_roundtrip :binary, ''
      it_should_roundtrip :binary, "\t\n"
      #it_should_roundtrip :binary, "\0\1" # TODO: the JSON gem does not handle this

      it_should_roundtrip :boolean, nil
      it_should_roundtrip :boolean, true
      it_should_roundtrip :boolean, false
    end
  end

  it_should_roundtrip_through(:to_serialized_attributes, :from_serialized_attributes)

  it_should_roundtrip_through(:to_ordered_query_string, :from_query_string) do
    it "should not be tripped up by delimiters in the keys" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :'a=x', :string
        attribute :'b&x', :string
      end
      original = klass.new("a=x" => "1", "b&x" => "2")
      roundtripped = klass.from_query_string(original.to_ordered_query_string)
      roundtripped.send("a=x").should == "1"
      roundtripped.send("b&x").should == "2"
    end

    it "should not be tripped up by delimiters in the values" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :a, :string
        attribute :b, :string
      end
      original = klass.new(:a => "1=2", :b => "3&4")
      roundtripped = klass.from_query_string(original.to_ordered_query_string)
      roundtripped.a.should == "1=2"
      roundtripped.b.should == "3&4"
    end
  end

  it_should_roundtrip_through(:to_ordered_json, :from_json) do
    it "should not be tripped up by delimiters in the keys" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :"'a':b,c", :string
      end
      original = klass.new("'a':b,c" => "1")
      roundtripped = klass.from_json(original.to_ordered_json)
      roundtripped.send("'a':b,c").should == "1"
    end

    it "should not be tripped up by delimiters in the values" do
      klass = Class.new(ActiveNomad::Base) do
        attribute :a, :string
      end
      original = klass.new(:a => "'a':b,c")
      roundtripped = klass.from_json(original.to_ordered_json)
      roundtripped.a.should == "'a':b,c"
    end
  end

  describe ".transaction" do
    before do
      @class = Class.new(ActiveNomad::Base) do
        cattr_accessor :transaction_called
        def self.transaction
          self.transaction_called = true
        end
      end
    end

    it "should be overridable to provide custom transaction semantics" do
      instance = @class.new
      instance.transaction{}
      instance.transaction_called.should be_true
    end

    it "should be called by #save" do
      instance = @class.new
      instance.transaction_called.should be_false
      instance.save
      instance.transaction_called.should be_true
    end
  end
end
