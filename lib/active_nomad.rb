require 'active_record'
require 'cgi'

module ActiveNomad
  NoPersistenceStrategy = Class.new(RuntimeError)

  class Base < ActiveRecord::Base
    #
    # Tell this record how to save itself.
    #
    def to_save(&proc)
      @save_proc = proc
    end

    #
    # Return the attributes of this object serialized as a valid query
    # string.
    #
    # Attributes are sorted by name.
    #
    def serialize
      self.class.columns.map do |column|
        name = column.name
        value = serialize_value(send(name), column.type) or
          next
        "#{CGI.escape(name)}=#{value}"
      end.compact.sort.join('&')
    end

    def self.deserialize(string)
      params = string ? CGI.parse(string.strip) : {}
      instance = new
      columns.map do |column|
        next if !params.key?(column.name)
        value = params[column.name].first
        instance.send "#{column.name}=", deserialize_value(value, column.type)
      end
      instance
    end

    protected

    #
    # Persist the object.
    #
    # The default is to call the block registered with
    # #to_save. Override if you don't want to use #to_save.
    #
    def persist
      @save_proc or
        raise NoPersistenceStrategy, "no persistence strategy - use #to_save to define one"
      @save_proc.call(self)
    end

    private

    class FakeAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
      def native_database_types
        @native_database_types ||= Hash.new{|h,k| h[k] = k.to_s}
      end

      def initialize
      end
    end

    FAKE_ADAPTER = FakeAdapter.new

    class << self
      #
      # Declare a column.
      #
      # Works like #add_column in a migration:
      #
      #     column :name, :string, :limit => 1, :null => false, :default => 'Joe'
      #
      def attribute(name, type, options={})
        sql_type = FAKE_ADAPTER.type_to_sql(type, options[:limit], options[:precision], options[:scale])
        columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, options[:default], sql_type, options[:null] != false)
        reset_column_information
      end

      def columns
        @columns ||= []
      end

      # Reset everything, except the column information
      def reset_column_information
        columns = @columns
        super
        @columns = columns
      end
    end

    self.abstract_class = true

    def create_or_update_without_callbacks
      errors.empty?
      persist
    end

    def serialize_value(value, type)
      return nil if value.nil?
      case type
      when :datetime, :timestamp, :time
        value.to_time.to_i.to_s
      when :date
        (value.to_date - DATE_EPOCH).to_i.to_s
      else
        CGI.escape(value.to_s)
      end
    end

    def self.deserialize_value(string, type)
      return nil if string.nil?
      case type
      when :datetime, :timestamp, :time
        Time.at(string.to_i)
      when :date
        DATE_EPOCH + string.to_i
      else
        CGI.unescape(string)
      end
    end

    DATE_EPOCH = Date.parse('1970-01-01')
  end
end
