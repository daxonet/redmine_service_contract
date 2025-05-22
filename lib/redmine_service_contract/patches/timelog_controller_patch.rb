module RedmineServiceContract
    module Patches
      module TimelogControllerPatch
        def self.included(base) # :nodoc:
          base.send(:include, InstanceMethods)
          
          base.class_eval do
              after_action :validate_services_contract, :only => [:update,:create]
          end
        end
  
          module InstanceMethods
            def validate_services_contract
              if @issue && @issue.service_contract && !@issue.service_contract.validate_hours_warning
                  flash[:warning] = flash[:warning].to_s + ' Service contract has exceeded warning level.'
              end
              if @issue && @issue.service_contract && @issue.service_contract.to_date && @issue.service_contract.to_date < Date.today
                  flash[:warning] = flash[:warning].to_s + ' Service contract has expired.'
              end
            end
          end
      end
    end
  end
  
  unless TimelogController.included_modules.include?(RedmineServiceContract::Patches::TimelogControllerPatch)
    TimelogController.send(:include, RedmineServiceContract::Patches::TimelogControllerPatch)
  end