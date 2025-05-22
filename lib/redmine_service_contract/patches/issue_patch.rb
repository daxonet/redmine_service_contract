module RedmineServiceContract
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:extend, ClassMethods)
        base.send(:include, InstanceMethods)
        base.send(:include, ActionView::Helpers::DateHelper)
        base.class_eval do
          
          has_one :service_contracts_issue, :dependent => :destroy
          has_one :service_contract, :through => :service_contracts_issue

          accepts_nested_attributes_for :service_contracts_issue
        end
      end

      module ClassMethods
        def load_services_contract_data(issues, _user = User.current)
          if issues.any?
            service_contracts_issues = ServiceContractsIssue.where(:issue_id => issues.map(&:id))
            issues.each do |issue|
              issue.instance_variable_set '@service_contracts_issue', (service_contracts_issues.detect { |c| c.issue_id == issue.id } || nil)
            end
          end
        end
      end
      
      module InstanceMethods
        def services_contract_number
          service_contract.number if service_contract
        end

        def services_contract_used_hours
          service_contracts_issue.used_hours if service_contracts_issue
        end
      end
    end
  end
end
  
unless Issue.included_modules.include?(RedmineServiceContract::Patches::IssuePatch)
  Issue.send(:include, RedmineServiceContract::Patches::IssuePatch)
end