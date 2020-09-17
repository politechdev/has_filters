# HasFilters

Dynamically create composable, SQL-backed ActiveRecord scopes that support various query operators (exact, range, etc) with minimal configuration.

It supports querying on table columns, virtual columns, associations, and arbitrary scopes. Designed with an intentional focus on filtering, it does not handle sorting, paginating, or rendering results, but it should work with any library that does, provided it similarly trades in [ActiveRecord::Relation](https://api.rubyonrails.org/classes/ActiveRecord/Relation.html) objects.

Caveats:

* Currently only tested on Postgresql. Other RDBMSs may not work as expected. Non-SQL data stores are not currently supported.
* No performance guarantees. For the most part, HasFilter scopes should perform similarly or better than plain ActiveRecord queries. However, in order to keep the interface as simple as possible, some composed queries rely on subqueries that can slow down execution speed compared to raw SQL.

[![CI status](https://github.com/politechdev/has_filters/workflows/CI/badge.svg)](https://github.com/politechdev/has_filters/actions)

### Basic usage

Configure:

    class SomeModel
      include HasFilters

      has_filters :first_name, :joined_model,
        scopes: %i(custom_scope),
        aliases: { full_name: "first_name || last_name" }

      def self.custom_scope(arg1)
        where(some_attr: arg1)
      end
    end

Filter:

    SomeModel.by_name("Hello")
    SomeModel.by_full_name("Hello World")
    SomeModel.by_joined_model_name(containing: "ello")
    SomeModel.filter([column: "custom_scope", param: ["argument"]])


For more information about these scopes and the arguments they accept, see [advanced usage](#advanced).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'has_filters'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install has_filters

## Advanced

When included in an `ActiveRecord::Model` HasFilters provides two complimentary APIs for filtering records:

1. Model scopes
2. Composable `filter` scope


### Scopes

  #### Columns

  Scopes are defined for any attribute passed to `has_filters`, prefixed with `by_`.

  ```
  has_filters :some_col

  Model.by_some_col("value")
  ```

  #### Operators

  By default, this scope performs an `exact` query.
  To specify a different operator, pass a hash with a king key value pair instead:

  `Model.by_some_col(containing: "value")`

  #### Associations

  To query on an association, both models must receive their own configuration.
  The source model should include the association it wants to filter on.
  This will define the same scope, namespaced, on both models.
  It also defines a scope on the source model suffixed with just the association name that queries the association by id.

  ```
  def SourceModel
    include HasFilters

    belongs_to :associated_model

    has_filters :associated_model
  end

  def AssociatedModel
    include HasFilters

    has_filters, :name
  end

  AssociatedModel.by_name("hi")
  SourceModel.by_associated_model_name("hi")
  SourceModel.by_associated_model(5)
  ```

  #### Virtual columns

  If you need to query on some derivation of the table data, you can do so using raw SQL to instruct `has_filters` how to build the alias.

  ```
  class SomeModel
    include HasFilters

    has_filters aliases: { full_name: "first_name || ' ' || last_name" }
  end

  SomeModel.by_full_name(containing: "Jack")
  ```

### Filter scope

  #### Composition

  Once you've configured some scopes, you probably want to filter one or more in your controller depending on some params.
  To facilitate this, `has_filters` provides the `filter` method, which accepts an array of rules and an instruction for how to compose them.
  Each rule should specify a filter to build the query for, a param, and an operator.

  ```
  params = [
    {
      column: 'first_name',
      operator: 'is'
      param: 'jack',
    },
    {
      column: 'last_name',
      operator: 'is',
      param: 'jack'
    }
  ]

  SomeModel.filter(rules: params)
  ```

  By default composed filters chain queries with 'AND', i.e. they are *exclusive*.
  To make queries *inclusive* (chained with 'OR'), specify the `conjunction`:

  `SomeModel.filter(rules: params, conjunction: 'inclusive')`

  #### Nesting

  In case you need to mix conjunctions with some filters excluding results and others including them, you can supply a composition rule instead of filter.
  Filters nested in this way are recursively composed using subqueries, so be sure to benchmark performance with representative data.

  ```
  params = [
    {
      rules: [
        {
          column: 'first_name',
          operator: 'is'
          param: 'jack',
        },
        {
          column: 'last_name',
          operator: 'is',
          param: 'jack'
        }
      ],
      conjunction: :inclusive
    },
    {
      rules: [
        {
          column: 'age',
          operator: 'more_than',
          param: 50
        }
      ]
    }
  ]

  SomeModel.filter(rules: params)
  ```

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the HasFilters project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tfwright/has_filters/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
