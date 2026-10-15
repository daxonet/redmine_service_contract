require 'minitest/autorun'

ContractLink = Struct.new(:service_contract_id, :use_spent_hours, :safe_attributes)
Contract = Struct.new(:id, :default_use_spent_hours)
FakeIssue = Struct.new(:service_contracts_issue, :service_contract, :tracker) do
  def blank? = false
  def build_service_contracts_issue = self.service_contracts_issue = ContractLink.new
end
FakeProject = Struct.new(:contract) do
  def default_service_contracts(_tracker) = contract
end

class IssuesController
  attr_accessor :params, :issue, :project, :updated, :build_calls
  def self.helper(*_args); end
  def self.after_action(*_args); end
  def initialize
    @params = {}
    @issue = FakeIssue.new(nil, nil, Object.new)
    @project = FakeProject.new(Contract.new(7, true))
    @updated = true
    @build_calls = 0
  end
  def new = :rendered
  protected
  def build_new_issue_from_params
    @build_calls += 1
    :built
  end
  def update_issue_from_params = @updated
end

module OtherIssueBuilder
  protected
  def build_new_issue_from_params = super
  def update_issue_from_params = super
end
IssuesController.prepend(OtherIssueBuilder)
require_relative '../lib/redmine_service_contract/patches/issues_controller_patch'

class IssuesControllerCompositionTest < Minitest::Test
  def test_new_issue_builder_composes_and_keeps_default_contract
    controller = IssuesController.new
    assert_equal :built, controller.send(:build_new_issue_from_params)
    assert_equal 1, controller.build_calls
    assert_equal 7, controller.instance_variable_get(:@issue).service_contracts_issue.service_contract_id
    assert controller.instance_variable_get(:@issue).service_contracts_issue.use_spent_hours
    assert_includes IssuesController.protected_instance_methods, :build_new_issue_from_params
  end

  def test_failed_core_update_is_not_overridden
    controller = IssuesController.new
    controller.updated = false
    controller.params = { service_contracts_issue: { service_contract_id: 9 } }
    refute controller.send(:update_issue_from_params)
    assert_nil controller.instance_variable_get(:@issue).service_contracts_issue
  end

  def test_successful_update_assigns_safe_contract_attributes
    controller = IssuesController.new
    controller.params = { service_contracts_issue: { service_contract_id: 9 } }
    assert controller.send(:update_issue_from_params)
    assert_equal({ service_contract_id: 9 }, controller.instance_variable_get(:@issue).service_contracts_issue.safe_attributes)
  end
end
