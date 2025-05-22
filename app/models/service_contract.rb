class ServiceContract < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :author, class_name: 'User'
  has_many :service_contracts_issue
  has_many :issues, :through => :service_contracts_issue
  has_and_belongs_to_many :trackers, lambda {order(:position)}

  scope :visible, ->(*args) { where(ServiceContract.visible_condition(args.shift || User.current, *args)).joins(:project) }
  
  scope :sorted, -> { order("#{table_name}.subject ASC") }
  
  validates :project_id, presence: true
  validates :author_id, presence: true
  validates :subject, presence: true

  safe_attributes *%w[number subject from_date to_date default_use_spent_hours is_default closed total_hours warning_hours error_hours custom_field_values custom_fields]
  safe_attributes 'project_id', if: ->(service_contract, _user) { service_contract.new_record? }
  safe_attributes 'tracker_ids'

  def initialize(attributes=nil, *args)
    super

    initialized = (attributes || {}).stringify_keys
    if !initialized.key?('trackers') && !initialized.key?('tracker_ids')
        self.trackers = Tracker.sorted.to_a
    end
  end

  def self.visible_condition(user, options = {})
    Project.allowed_to_condition(user, :view_service_contracts, options)
  end

  def self.css_icon
    'icon icon-user'
  end

  def editable_by?(user)
    editable?(user)
  end


  def visible?(user = nil)
    user ||= User.current
    user.allowed_to?(:view_service_contracts, project, global: true)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_service_contracts, project, global: true)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:manage_service_contracts, project, global: true)
  end

  def attachments_visible?(user = nil)
    visible?(user)
  end

  def attachments_editable?(user = nil)
    editable?(user)
  end

  def attachments_deletable?(user = nil)
    deletable?(user)
  end

  def fixed_hours(exclude_issue_id = 0)
    h = ServiceContractsIssue
    .select("sum(hours) hours")
    .where(service_contract_id: self.id)
    .where(use_spent_hours: false)
    .where.not(issue_id: exclude_issue_id)
    .first
    .attributes['hours']
    if h.nil?
      h = 0
    end
    h.to_f
  end

  def spent_hours(exclude_issue_id = 0)
    h = TimeEntry
    .joins("JOIN #{ServiceContractsIssue.table_name} on #{ServiceContractsIssue.table_name}.issue_id = time_entries.issue_id")
    .select("sum(time_entries.hours) hours")
    .where("#{ServiceContractsIssue.table_name}.service_contract_id = ?", id)
    .where("#{ServiceContractsIssue.table_name}.use_spent_hours = ?", true) 
    .where("#{ServiceContractsIssue.table_name}.issue_id != ?", exclude_issue_id)
    .first
    .attributes['hours']
    if h.nil?
      h = 0
    end
    h.to_f
  end

  def total_used_hours(exclude_issue_id = 0)
    total = 0
    if exclude_issue_id == 0
      total = fixed_hours  + spent_hours
    else
      total = fixed_hours(exclude_issue_id) + spent_hours(exclude_issue_id)
    end
    total
  end

  def total_used_hours_with_current(service_contracts_issue)
    total = 0
    if service_contracts_issue
      total = total_used_hours(service_contracts_issue.issue_id)
      if service_contracts_issue.use_spent_hours
        total += service_contracts_issue.issue.total_spent_hours
      elsif service_contracts_issue.hours
        total += service_contracts_issue.hours
      end
      total
    else
      total = total_used_hours
    end
    total
  end

  def total_issue
    issues.count
  end

  def remain_hours
    total_hours - total_used_hours if total_hours
  end

  def validate_hours_error(service_contracts_issue)
    if error_hours.nil? || (error_hours.to_f) == 0
      true
    else
      used = total_used_hours_with_current(service_contracts_issue)
      if used.to_f > error_hours.to_f
        false
      else
        true
      end
    end
  end

  def validate_hours_warning
    if warning_hours.nil? || (warning_hours.to_f) == 0
      true
    else
      if total_used_hours.to_f > warning_hours.to_f
        false
      else
        true
      end
    end
  end

  def to_s
    s = number.to_s + ' ' + subject.to_s
    if to_date
      s = s + ' (Expired:' + to_date.to_formatted_s(:db) + ')'
    end

    s = s + ' Used: ' + format("%.2f", total_used_hours.to_f)

    if total_hours
      s = s + ' Remain: ' + format("%.2f", remain_hours.to_f)
    end

  end

  alias_attribute :created_on, :created_at
  alias_attribute :updated_on, :updated_at


end
