module RedmineServiceContract
  module Patches
    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        
        base.class_eval do                      
            helper :service_contracts

            after_action :validate_services_contract, :only => [:update,:create]

            alias_method :new_without_services_contract, :new
            alias_method :new, :new_with_services_contract
            alias_method :build_new_issue_from_params_without_services_contract, :build_new_issue_from_params
            alias_method :build_new_issue_from_params, :build_new_issue_from_params_with_services_contract
            alias_method :update_issue_from_params_without_services_contract, :update_issue_from_params
            alias_method :update_issue_from_params, :update_issue_from_params_with_services_contract            
        end
      end

        module InstanceMethods
          def validate_services_contract
            if @issue.service_contract && !@issue.service_contract.validate_hours_warning
                flash[:warning] = flash[:warning].to_s + ' Service contract has exceeded warning level.'
            end
            if @issue.service_contract && @issue.service_contract.to_date && @issue.service_contract.to_date < Date.today
                flash[:warning] = flash[:warning].to_s + ' Service contract has expired.'
            end
          end

          def new_with_services_contract
            if params[:service_contracts_issue]
                @issue.service_contracts_issue.safe_attributes = params[:service_contracts_issue]
            end
            new_without_services_contract
          end

          def build_new_issue_from_params_with_services_contract
            build_new_issue_from_params_without_services_contract
            
            return if @issue.blank?

            @issue.build_service_contracts_issue unless @issue.service_contracts_issue

            if @issue.service_contract.nil?
              default_service_contract = @project.default_service_contracts(@issue.tracker)
              unless default_service_contract.nil?
                @issue.service_contracts_issue.service_contract_id = default_service_contract.id if default_service_contract
                @issue.service_contracts_issue.use_spent_hours = default_service_contract.default_use_spent_hours if default_service_contract
              end
            end
          end

          def update_issue_from_params_with_services_contract
            is_updated = update_issue_from_params_without_services_contract
            return false unless is_updated
            if params[:service_contracts_issue]
                @issue.service_contracts_issue ||= @issue.build_service_contracts_issue
                @issue.service_contracts_issue.safe_attributes = params[:service_contracts_issue]
            end
            is_updated
          end
        end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineServiceContract::Patches::IssuesControllerPatch)
    IssuesController.send(:include, RedmineServiceContract::Patches::IssuesControllerPatch)
end