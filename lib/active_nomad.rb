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
    # Return an ActiveSupport::OrderedHash of serialized attributes.
    #
    # Attributes are sorted by name. Each value is either a string or
    # nil.
    #
    def to_serialized_attributes
      attributes = ActiveSupport::OrderedHash.new
      columns = self.class.columns_hash
      self.class.column_names.sort.each do |name|
        column = columns[name] or
          next
        attributes[name] = serialize_value(send(name), column.type)
      end
      attributes
    end

    #
    # Recreate an object from a serialized string.
    #
    def self.from_serialized_attributes(deserialized_attributes)
      instance = new
      deserialized_attributes.each do |name, serialized_value|
        column = columns_hash[name.to_s] or
          next
        instance.send "#{column.name}=", deserialize_value(serialized_value, column.type)
      end
      instance
    end

    #
    # Serialize this record as a query string.
    #
    # Attributes are sorted by name.
    #
    def to_ordered_query_string
      to_serialized_attributes.map do |name, value|
        next nil if value.nil?
        "#{CGI.escape(name)}=#{CGI.escape(value)}"
      end.compact.sort.join('&')
    end

    #
    # Deserialize this record from a query string returned by
    # #to_ordered_query_string.
    #
    def self.from_query_string(string)
      return new if string.blank?
      serialized_attributes = string.strip.split(/&/).map do |pair|
        name, value = pair.split(/=/, 2)
        [CGI.unescape(name), CGI.unescape(value)]
      end
      from_serialized_attributes(serialized_attributes)
    end

    #
    # Serialize this record as a JSON string.
    #
    # Attributes are sorted by name.
    #
    def to_ordered_json
      to_serialized_attributes.to_json
    end

    #
    # Deserialize this record from a JSON string returned by
    # #to_ordered_json.
    #
    def self.from_json(string)
      return new if string.blank?
      begin
        serialized_attributes = JSON.parse(string)
      rescue JSON::ParserError
        serialized_attributes = {}
      end
      from_serialized_attributes(serialized_attributes)
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

    class FakeAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter # :nodoc:
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

      def columns # :nodoc:
        @columns ||= superclass.columns.dup
      end

      def reset_column_information # :nodoc:
        # Reset everything, except the column information.
        columns = @columns
        super
        @columns = columns
      end

      #
      # Override to provide custom transaction semantics.
      #
      # The default #transaction simply yields to the given block.
      #
      def transaction
        yield
      end
    end

    @columns = []
    self.abstract_class = true

    def create_or_update_without_callbacks
      errors.empty?
      persist
    end

    def serialize_value(value, type)
      return nil if value.nil?
      case type
      when :datetime, :timestamp, :time
        # The day in RFC 2822 is optional - chop it.
        value.rfc2822.sub(/\A[A-Za-z]{3}, /, '')
      when :date
        value.to_date.strftime(DATE_FORMAT)
      else
        value.to_s
      end
    end

    def self.deserialize_value(string, type)
      return nil if string.nil?
      case type
      when :datetime, :timestamp, :time
        Time.parse(string)
      when :date
        Date.parse(string)
      else
        string
      end
    end

    DATE_FORMAT = '%d %b %Y'.freeze
  end
end
