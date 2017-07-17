object false
node(:collection_size) { |m| @total_items_count}
child(@items) { 

  collection @items

  attributes :id, :number, :par_level
  node(:name) do |item|
    "#{ (controller.render_to_string('shared/_open_pr_po_for_item', locals:{ item: item })) } #{ link_to(item.name, edit_item_path(item)) }"
  end
  node(:unit) { |item| item.unit.name.upcase }
  node(:vendors) do |item|
    vendor_to_display = item.vendor_items.select(&:preferred).first.try(:vendor) || item.vendors.first
    "#{ vendor_to_display.try(:name) }#{ '<br>' + raw( t('items.item.more_vendors', count: item.vendors.count - 1)) if item.vendors.count > 1 }"
  end
}