Redmine::Plugin.register :redmine_service_contract do
  name 'Redmine Service Contract'
  author 'LS MARK'
  description 'This is a plugin for maintain service contract'
  version '2.0.1'
  url 'https://daxonet.com'
  author_url 'https://daxonet.com/about'

  Redmine::AccessControl.map do |map|
    map.project_module :service_contracts do |pmap|
      pmap.permission :view_service_contracts, { service_contracts: [:index, :show, :autocomplete, :context_menu] }, read: true
      pmap.permission :manage_service_contracts, { service_contracts: [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update] }
    end 
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :service_contracts, { controller: 'service_contracts', action: 'index', project_id: nil }, caption: :label_service_contracts
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :service_contracts, { controller: 'service_contracts', action: 'index' }, param: :project_id, caption: :label_service_contracts
  end

  Redmine::Search.map do |search|
    search.register :service_contracts
  end
end

require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/patches/issue_patch'
require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/patches/issue_query_patch'
require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/patches/issues_controller_patch'
require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/patches/project_patch'
require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/patches/timelog_controller_patch'
require_dependency File.dirname(__FILE__) + '/lib/redmine_service_contract/hooks'