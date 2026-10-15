# Run without a Redmine database: ruby test/issue_query_patch_composition_test.rb
require 'minitest/autorun'

def require_dependency(_name); end

QueryColumn = Struct.new(:name) do
  def initialize(name, **_options)
    super(name)
  end
end

class User
  class << self
    attr_accessor :current
  end
end

class Issue
  def self.table_name = 'issues'
  def self.load_services_contract_data(issues) = issues.each { |issue| issue[:loaded] = true }
end

class ServiceContractsIssue
  def self.table_name = 'service_contracts_issues'
end

class IssueQuery
  def available_filters = (@available_filters ||= { 'status_id' => {} })
  def available_columns = (@available_columns ||= [QueryColumn.new(:id)])
  def add_available_filter(name, options) = @available_filters[name] = options
  def issues(options = {}) = [{ limit: options[:limit] }]
  def joins_for_order_statement(_order) = nil
  def has_column?(_name) = true
  def project = nil
  def l(key) = key.to_s
end

# Exercise another plugin wrapping the same methods before this plugin loads.
module OtherQueryExtension
  def available_filters
    super.merge!('other_plugin' => {})
  end

  def available_columns
    columns = super
    columns << QueryColumn.new(:other_plugin) unless columns.any? { |column| column.name == :other_plugin }
    columns
  end
end
IssueQuery.prepend(OtherQueryExtension)

require_relative '../lib/redmine_service_contract/patches/issue_query_patch'

class IssueQueryPatchCompositionTest < Minitest::Test
  Permission = Struct.new(:allowed) do
    def allowed_to?(*_args) = allowed
  end

  def setup
    User.current = Permission.new(true)
    @query = IssueQuery.new
  end

  def test_filters_compose_without_recursion
    2.times do
      assert_equal %w[other_plugin services_contract_number status_id], @query.available_filters.keys.sort
    end
  end

  def test_columns_preserve_other_extensions_without_duplicates
    2.times { @query.available_columns }
    names = @query.available_columns.map(&:name)
    assert_includes names, :other_plugin
    assert_equal 1, names.count(:services_contract_number)
    assert_equal 1, names.count(:services_contract_used_hours)
  end

  def test_contract_fields_require_permission
    User.current = Permission.new(false)
    refute @query.available_filters.key?('services_contract_number')
    refute_includes @query.available_columns.map(&:name), :services_contract_number
  end

  def test_issue_options_are_forwarded_and_contract_data_is_loaded
    assert_equal [{ limit: 2, loaded: true }], @query.issues(limit: 2)
  end

  def test_contract_order_joins_the_relation_table
    assert_includes @query.joins_for_order_statement('services_contract_number'),
                    'LEFT OUTER JOIN service_contracts_issues ON issues.id = service_contracts_issues.issue_id'
    assert_nil @query.joins_for_order_statement('id')
  end
end
