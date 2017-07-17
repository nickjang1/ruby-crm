class CreateBrands < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.string :name
    end

    ["Rubbermaid", "Sonoco", "GuestTex", "Ecolab", "LaFresh", "Sheila Shine", "HGI Bic", "HGI Stancap", "Alliance",
    "Clorox", "HGI", "Homz EasyBoard", "Nitrile", "Mr. Clean", "Guest Choice"].each{|name| Brand.create(name: name) }
  end
end
