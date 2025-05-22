module RedmineServiceContract
  class Hooks < Redmine::Hook::ViewListener
    
    render_on :view_issues_show_description_bottom,
              :partial => 'issues/view_service_contract'
    render_on :view_issues_form_details_bottom,
              :partial => 'issues/edit_service_contract'

    #def controller_issues_edit_before_save(context = {})
    #  controller_issues_before_save(context)    
    #end
    
    def controller_issues_new_before_save(context = {})
      @service_contracts_issue = context[:issue].service_contracts_issue || ServiceContractsIssue.new #|| ServiceContractsIssue.where('issue_id', context[:issue].id).first #
      if context[:params]['service_contracts_issue']
        @service_contracts_issue.safe_attributes = context[:params]['service_contracts_issue']
      end
      context[:issue].service_contracts_issue = @service_contracts_issue
    end

    #def controller_issues_before_save(context = {})
      
    #end
  end
end
