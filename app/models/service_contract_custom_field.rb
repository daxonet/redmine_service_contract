class ServiceContractCustomField < CustomField

  def type_name
    :label_service_contracts
  end

  def form_fields
    [:is_filter, :searchable, :is_required]
  end

end
