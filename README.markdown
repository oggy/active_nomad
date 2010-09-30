# Active Nomad

ActiveRecord objects with a customizable persistence strategy.

## Why

Sometimes you want an Active Record object that does not live in the database.
Perhaps it never needs to be persisted, or you'd like to store it in a cookie,
or some other store, but it would still be handy to have ActiveRecord's ability
to cast values, run validations, or fire callbacks.

Ideally, the persistence strategy would be pluggable. With Active Nomad, it is!

## How

Subclass from ActiveNomad::Base and declare your attributes with the
`attribute` class method. The arguments look just like creating a column in a
migration:

    class Thing < ActiveNomad::Base
      attribute :name, :string, :limit => 20
    end

To persist the record, Active Nomad calls `persist`, which calls a
Proc registered by `to_save`. For example, here's how you could
persist to a cookie:

    thing = Thing.deserialize(cookies[:thing])
    thing.to_save do |thing|
      cookies[:thing] = thing.serialize
      true
    end

Things to note:

 * Active Nomad defines `serialize` and `deserialize` which will
   serialize to and from a valid query string with predictable
   attribute order (i.e., appropriate for a cookie).
 * The proc should return true if persistence was successful, false
   otherwise. This will be the return value of `save`, etc.
 * You may alternatively override `persist` in a subclass if you
   don't want to register a proc for every instance.

## Transactions

In addition to customizing persistence, you can also customize
transaction semantics by overriding the `transaction` class method in
a base class. Example:

    class RedisNomad < ActiveNomad::Base
      def self.transaction
        redis.multi
        begin
          yield
          redis.exec
        rescue Exception => e
          redis.discard
          raise
        end
      end

      def self.redis
        @redis ||= Redis.new
      end
    end

`ActiveNomad::Base.transaction` simply calls the given block with no
real transaction semantics.

## Notes

Only ActiveRecord 2.3 compatible. ActiveRecord 3.0 has a more modular
architecture which makes this largely unnecessary.

## Contributing

 * Bug reports: http://github.com/oggy/active_nomad/issues
 * Source: http://github.com/oggy/active_nomad
 * Patches: Fork on Github, send pull request.
   * Ensure patch includes tests.
   * Leave the version alone, or bump it in a separate commit.

## Copyright

Copyright (c) 2010 George Ogata. See LICENSE for details.

## Credit

Inspired by Jonathan Viney's ActiveRecord::BaseWithoutTable.
