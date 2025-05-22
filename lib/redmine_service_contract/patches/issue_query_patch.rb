require_dependency 'query'

module RedmineServiceContract
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do         
          alias_method :available_columns_without_services_contract, :available_columns
          alias_method :available_columns, :available_columns_with_services_contract
          alias_method :available_filters_without_services_contract, :available_filters
          alias_method :available_filters, :available_filters_with_services_contract
          alias_method :joins_for_order_statement_without_services_contract, :joins_for_order_statement
          alias_method :joins_for_order_statement, :joins_for_order_statement_with_services_contract
          alias_method :issues_without_services_contract, :issues
          alias_method :issues, :issues_with_services_contract
        end
      end

      module InstanceMethods
        def issues_with_services_contract(options = {})
          issues = issues_without_services_contract(options)
          if has_column?(:services_contract_number)
            Issue.load_services_contract_data(issues)
          end
          issues
        end

        def joins_for_order_statement_with_services_contract(order_options)
          joins = joins_for_order_statement_without_services_contract(order_options)
          ticket_joins = [joins].flatten
          if order_options && (order_options.include?('services_contract_number'))
            ticket_joins << "LEFT OUTER JOIN #{service_contracts_issue.table_name} ON #{Issue.table_name}.id = #{service_contracts_issue.table_name}.issue_id"
          end
          ticket_joins.any? ? ticket_joins.join(' ') : nil
        end

        def sql_for_services_contract_number_field(_field, operator, value)
          "(#{Issue.table_name}.id IN (SELECT #{ServiceContractsIssue.table_name}.issue_id FROM #{ServiceContractsIssue.table_name}
                                WHERE #{ServiceContractsIssue.table_name}.service_contract_id IN (
                                  SELECT #{ServiceContract.table_name}.id
                                  FROM #{ServiceContract.table_name}
                                  WHERE #{sql_for_field(_field, operator,value,ServiceContract.table_name,"number")}
                                )))"
        end

        def available_columns_with_services_contract
          if @available_columns.blank? && User.current.allowed_to?(:view_service_contracts, project, :global => true)
            @available_columns = available_columns_without_services_contract
            @available_columns << QueryColumn.new(:services_contract_number, :caption => :services_contract_number)
            @available_columns << QueryColumn.new(:services_contract_used_hours, caption: l(:label_service_contract_used), title:l(:label_service_contract_used))         
          else
            available_columns_without_services_contract
          end
          @available_columns
        end

        def available_filters_with_services_contract
          if @available_filters.blank? && User.current.allowed_to?(:view_service_contracts, project, :global => true)
            add_available_filter('services_contract_number', type: :string, name: l(:services_contract_number)) unless available_filters_without_services_contract.key?('services_contract_number')
          else
            available_filters_without_services_contract
          end
          @available_filters
        end
      end
    end
  end
end

unless IssueQuery.included_modules.include?(RedmineServiceContract::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineServiceContract::Patches::IssueQueryPatch)
end
