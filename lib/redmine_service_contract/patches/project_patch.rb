module RedmineServiceContract
  module Patches
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_many :service_contracts
        end
      end
      
      module InstanceMethods
        def open_service_contracts
            service_contracts.select { |service_contract| !service_contract.closed }
        end
        def open_service_contracts_for_all_ancestor_projects(contracts=self.open_service_contracts)
          if self.parent != nil
            parent = self.parent
            contracts +=  parent.open_service_contracts_for_all_ancestor_projects
          end
          return contracts
        end
        def open_service_contracts_tracker(tracker)
          service_contracts.select { |service_contract| !service_contract.closed && service_contract.trackers.include?(tracker)   }
        end
        def open_service_contracts_for_all_ancestor_projects_tracker(tracker,contracts=self.open_service_contracts_tracker(tracker))
          if self.parent != nil
            parent = self.parent
            contracts +=  parent.open_service_contracts_for_all_ancestor_projects_tracker(tracker)
          end
          return contracts
        end
        def has_service_contracts(tracker)
          return open_service_contracts_for_all_ancestor_projects_tracker(tracker).length != 0
        end
        def default_service_contracts(tracker)
          service_contracts.select { |service_contract| !service_contract.closed && service_contract.trackers.include?(tracker) && service_contract.is_default  }.first
        end
      end
    end
  end
end
      
unless Project.included_modules.include?(RedmineServiceContract::Patches::ProjectPatch)
  Project.send(:include, RedmineServiceContract::Patches::ProjectPatch)
end