require 'inactive_record'

# TODO: This should not be necessary - we're not stubbing out enough.
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
