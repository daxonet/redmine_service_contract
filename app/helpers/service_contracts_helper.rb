module ServiceContractsHelper
    #helper :queries

  def _project_service_contract_path(project, action_name = 'show', *args)
    if action_name == 'show'
      if project
        project_service_contract_path(project, *args)
      else
        service_contract_path(*args)
      end
    else
      if project
        timelog_project_service_contract_path(project, *args)
      else
        timelog_service_contract_path(*args)
      end
    end
  end

  def _project_service_contracts_path(project, *args)
    if project
      project_service_contracts_path(project, *args)
    else
      service_contracts_path(*args)
    end
  end

  def service_contract_column_content(column, item)
    value = column.value_object(item)
    if value.is_a?(Array)
      values = value.collect {|v| service_contract_column_value(column, item, v)}.compact
      safe_join(values, ', ')
    else
      service_contract_column_value(column, item, value)
    end
  end
    
  def service_contract_column_value(column, item, value)
    case column.name
    when :number
      link_to value, service_contract_path(item)
    when :subject
      format_object(value)  
    else
      column_value(column, item, value)
    end
  end

  def find_create_service_contracts_issue(issue)
    if issue
      ServiceContractsIssue.where('issue_id', issue.id).first || ServiceContractsIssue.new(:issue_id => issue.id)
    else
      ServiceContractsIssue.new
    end
  end
end
