class ServiceContractTimelog < ActiveRecord::Base
    belongs_to :issue
    belongs_to :project
    belongs_to :service_contract
    belongs_to :user
    belongs_to :time_entry
    belongs_to :activity, :class_name => 'TimeEntryActivity'
    belongs_to :searchable, polymorphic: true
    def readonly?
      true
    end

    
    scope :left_join_time_entry, lambda {
      joins("LEFT OUTER JOIN #{TimeEntry.table_name} ON #{TimeEntry.table_name}.id = #{table_name}.time_entry_id")
    }

    #scope :left_join_activity, lambda {
    #    joins("LEFT OUTER JOIN #{Activity.table_name} ON #{Activity.table_name}.id = #{ServiceContractTimelog.table_name}.activity_id")
    #}
end