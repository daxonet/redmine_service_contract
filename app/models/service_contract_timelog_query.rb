class ServiceContractTimelogQuery < Query
  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :service_contract
  class_attribute :service_contract

  self.queried_class = ServiceContractTimelog
  self.view_permission = :view_time_entries

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= {  }
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:issue_id, caption: '#')
    @available_columns << QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true)
    @available_columns << QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.id")
    @available_columns << QueryColumn.new(:spent_on, :sortable => "#{ServiceContractTimelog.table_name}.spent_on", :default_order => 'desc', :groupable => true)
    @available_columns << QueryColumn.new(:comments)
    @available_columns << QueryColumn.new(:user, :sortable => lambda {User.fields_for_order_statement}, :groupable => true)
    @available_columns << QueryColumn.new(:hours, :sortable => "#{ServiceContractTimelog.table_name}.hours", :totalable => true)
    @available_columns << QueryColumn.new(:activity, :sortable => "#{TimeEntryActivity.table_name}.position", :groupable => true)
    @available_columns += TimeEntryCustomField.visible.
                            map {|cf| QueryAssociationCustomFieldColumn.new(:time_entry,cf) }
    @available_columns += issue_custom_fields.visible.
                            map {|cf| QueryAssociationCustomFieldColumn.new(:issue, cf, :totalable => false) }
    @available_columns += ProjectCustomField.visible.
                            map {|cf| QueryAssociationCustomFieldColumn.new(:project, cf) }
  end

  def initialize_available_filters
    add_available_filter(
      "user_id",
      :type => :list, :values => lambda { author_values }
    )

    add_custom_fields_filters(TimeEntryCustomField, :time_entry)
    add_associations_custom_fields_filters :project
    add_custom_fields_filters(issue_custom_fields, :issue)
    add_associations_custom_fields_filters :user

  end

  scope :visible, lambda {|*args|
    joins(:project).
    where(TimeEntry.visible_condition(args.shift || User.current, *args))
  }

  scope :on_issue, lambda {|issue|
    joins(:issue).
    where("#{Issue.table_name}.root_id = #{issue.root_id} AND #{Issue.table_name}.lft >= #{issue.lft} AND #{Issue.table_name}.rgt <= #{issue.rgt}")
  }

  # Returns a SQL conditions string used to find all time entries visible by the specified user
  def self.visible_condition(user, options={})
    Project.allowed_to_condition(user, :view_time_entries, options) do |role, user|
      if role.time_entries_visibility == 'all'
        nil
      elsif role.time_entries_visibility == 'own' && user.id && user.logged?
        "#{table_name}.user_id = #{user.id}"
      else
        '1=0'
      end
    end
  end

  def default_columns_names
    @default_columns_names ||= [ "spent_on", "issue", "comments","user","hours"].flat_map{|c| [c.to_s, c.to_sym]}
  end

  # Returns true if user or current user is allowed to view the time entry
  def visible?(user=nil)
    (user || User.current).allowed_to?(:view_time_entries, self.project) do |role, user|
      if role.time_entries_visibility == 'all'
        true
      elsif role.time_entries_visibility == 'own'
        self.user == user
      else
        false
      end
    end
  end

  def set_project_if_nil
    self.project = issue.project if issue && project.nil?
  end

  def set_author_if_nil
    self.author = User.current if author.nil?
  end

  def hours
    h = read_attribute(:hours)
    if h.is_a?(Float)
      h.round(2)
    else
      h
    end
  end

  def service_contract_timelogs(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
    # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
    unless ["#{ServiceContractTimelog.table_name}.spent_on DESC", "#{ServiceContractTimelog.table_name}.spent_on ASC"].any?{|i| order_option.include?(i)}
      order_option << "#{ServiceContractTimelog.table_name}.spent_on ASC"
    end

    scope = ServiceContractTimelog.
      joins(:project,:issue).
      includes(:activity).
      references(:activity).
      left_join_time_entry.
      where(statement).
      includes(([:project] + (options[:include] || [])).uniq).
      where(options[:conditions]).
      order(order_option).
      joins(joins_for_order_statement(order_option.join(','))).
      limit(options[:limit]).
      offset(options[:offset])
    
    scope = scope.preload([:user_id] & columns.map(&:name))
    
    scope.to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def statement
    filters_clauses = [super]
    filters_clauses << service_contract_statement
    filters_clauses.any? ? filters_clauses.join(' AND ') : nil
  end

  def service_contract_statement
    "(#{ServiceContractTimelog.table_name}.service_contract_id = #{service_contract.id})" if service_contract
  end

end