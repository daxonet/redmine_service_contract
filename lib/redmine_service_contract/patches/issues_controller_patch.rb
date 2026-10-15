module RedmineServiceContract
  module Patches
    module IssuesControllerPatch
      def self.prepended(base)
        base.helper :service_contracts
        base.after_action :validate_services_contract, only: [:update, :create]
      end

      def new
        if params[:service_contracts_issue]
          @issue.service_contracts_issue.safe_attributes = params[:service_contracts_issue]
        end
        super
      end

      protected

      def build_new_issue_from_params
        result = super
        return result if @issue.blank?

        @issue.build_service_contracts_issue unless @issue.service_contracts_issue
        if @issue.service_contract.nil?
          contract = @project.default_service_contracts(@issue.tracker)
          if contract
            @issue.service_contracts_issue.service_contract_id = contract.id
            @issue.service_contracts_issue.use_spent_hours = contract.default_use_spent_hours
          end
        end
        result
      end

      def update_issue_from_params
        updated = super
        return false unless updated

        if params[:service_contracts_issue]
          @issue.service_contracts_issue ||= @issue.build_service_contracts_issue
          @issue.service_contracts_issue.safe_attributes = params[:service_contracts_issue]
        end
        updated
      end

      private

      def validate_services_contract
        return unless @issue

        contract = @issue.service_contract
        if contract && !contract.validate_hours_warning
          flash[:warning] = flash[:warning].to_s + ' Service contract has exceeded warning level.'
        end
        if contract && contract.to_date && contract.to_date < Date.today
          flash[:warning] = flash[:warning].to_s + ' Service contract has expired.'
        end
      end
    end
  end
end

unless IssuesController.ancestors.include?(RedmineServiceContract::Patches::IssuesControllerPatch)
  IssuesController.prepend(RedmineServiceContract::Patches::IssuesControllerPatch)
end
