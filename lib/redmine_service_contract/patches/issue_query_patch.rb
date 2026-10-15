require_dependency 'query'

module RedmineServiceContract
  module Patches
    module IssueQueryPatch
        def issues(options = {})
          issues = super(options)
          if has_column?(:services_contract_number)
            Issue.load_services_contract_data(issues)
          end
          issues
        end

        def joins_for_order_statement(order_options)
          joins = super(order_options)
          ticket_joins = [joins].flatten
          if order_options && (order_options.include?('services_contract_number'))
            ticket_joins << "LEFT OUTER JOIN #{ServiceContractsIssue.table_name} ON #{Issue.table_name}.id = #{ServiceContractsIssue.table_name}.issue_id"
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

        def available_columns
          columns = super
          if User.current.allowed_to?(:view_service_contracts, project, :global => true)
            unless columns.any? { |column| column.name == :services_contract_number }
              columns << QueryColumn.new(:services_contract_number, :caption => :services_contract_number)
            end
            unless columns.any? { |column| column.name == :services_contract_used_hours }
              columns << QueryColumn.new(:services_contract_used_hours, caption: l(:label_service_contract_used), title: l(:label_service_contract_used))
            end
          end
          columns
        end

        def available_filters
          filters = super
          if User.current.allowed_to?(:view_service_contracts, project, :global => true) && !filters.key?('services_contract_number')
            add_available_filter('services_contract_number', type: :string, name: l(:services_contract_number))
          end
          filters
        end
    end
  end
end

unless IssueQuery.ancestors.include?(RedmineServiceContract::Patches::IssueQueryPatch)
  IssueQuery.prepend(RedmineServiceContract::Patches::IssueQueryPatch)
end
