class ServiceContractQuery < Query

  self.queried_class = ServiceContract

  def initialize_available_filters
    add_available_filter 'subject', name: ServiceContract.human_attribute_name(:subject), type: :string
    add_available_filter 'number', name: ServiceContract.human_attribute_name(:number), type: :string
    add_available_filter 'from_date', name: ServiceContract.human_attribute_name(:from_date), type: :date
    add_available_filter 'to_date', name: ServiceContract.human_attribute_name(:to_date), type: :date
    add_available_filter 'default_use_spent_hours', name: ServiceContract.human_attribute_name(:default_use_spent_hours), type: :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
    add_available_filter 'is_default', name: ServiceContract.human_attribute_name(:is_default), :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
    add_available_filter 'closed', name: ServiceContract.human_attribute_name(:closed), type: :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]
    add_available_filter 'total_hours', name: ServiceContract.human_attribute_name(:total_hours), type: :float
    add_available_filter 'warning_hours', name: ServiceContract.human_attribute_name(:warning_hours), type: :float
    add_available_filter 'error_hours', name: ServiceContract.human_attribute_name(:error_hours), type: :float
    add_available_filter 'created_at', name: ServiceContract.human_attribute_name(:created_at), type: :date
    add_available_filter 'updated_at', name: ServiceContract.human_attribute_name(:updated_at), type: :date

    add_custom_fields_filters(ServiceContractCustomField)
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = []
    group = l("label_filter_group_#{self.class.name.underscore}")

    @available_columns << QueryColumn.new(:subject, caption: ServiceContract.human_attribute_name(:subject), title: ServiceContract.human_attribute_name(:subject), group: group)
    @available_columns << QueryColumn.new(:number, caption: ServiceContract.human_attribute_name(:number), title: ServiceContract.human_attribute_name(:number), group: group)
    @available_columns << QueryColumn.new(:from_date, caption: ServiceContract.human_attribute_name(:from_date), title: ServiceContract.human_attribute_name(:from_date), group: group)
    @available_columns << QueryColumn.new(:to_date, caption: ServiceContract.human_attribute_name(:to_date), title: ServiceContract.human_attribute_name(:to_date), group: group)
    @available_columns << QueryColumn.new(:total_used_hours, caption: l(:label_service_contract_used), title:l(:label_service_contract_used), group: group)
    @available_columns << QueryColumn.new(:default_use_spent_hours, caption: ServiceContract.human_attribute_name(:default_use_spent_hours), title: ServiceContract.human_attribute_name(:default_use_spent_hours), group: group)
    @available_columns << QueryColumn.new(:is_default, caption: ServiceContract.human_attribute_name(:is_default), title: ServiceContract.human_attribute_name(:is_default), group: group)
    @available_columns << QueryColumn.new(:closed, caption: ServiceContract.human_attribute_name(:closed), title: ServiceContract.human_attribute_name(:closed), group: group)
    @available_columns << QueryColumn.new(:total_hours, caption: ServiceContract.human_attribute_name(:total_hours), title: ServiceContract.human_attribute_name(:total_hours), group: group)
    @available_columns << QueryColumn.new(:warning_hours, caption: ServiceContract.human_attribute_name(:warning_hours), title: ServiceContract.human_attribute_name(:warning_hours), group: group)
    @available_columns << QueryColumn.new(:error_hours, caption: ServiceContract.human_attribute_name(:error_hours), title: ServiceContract.human_attribute_name(:error_hours), group: group)
    @available_columns << QueryColumn.new(:created_at, caption: ServiceContract.human_attribute_name(:created_at), title: ServiceContract.human_attribute_name(:created_at), group: group)
    @available_columns << QueryColumn.new(:updated_at, caption: ServiceContract.human_attribute_name(:updated_at), title: ServiceContract.human_attribute_name(:updated_at), group: group)
    @available_columns += ServiceContractCustomField.visible.collect { |cf| QueryCustomFieldColumn.new(cf) }

    @available_columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { "closed" => {:operator => "=", :values => ["0"]} }
  end

  def default_columns_names
    super.presence || [ "number", "subject", "from_date","to_date","total_hours","total_used_hours"].flat_map{|c| [c.to_s, c.to_sym]}
  end

  def service_contracts(options={})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)

    scope = ServiceContract.visible.
        where(statement).
        includes(((options[:include] || [])).uniq).
        where(options[:conditions]).
        order(order_option).
        joins(joins_for_order_statement(order_option.join(','))).
        limit(options[:limit]).
        offset(options[:offset])

    if has_custom_field_column?
      scope = scope.preload(:custom_values)
    end

    service_contracts = scope.to_a

    service_contracts
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
end
