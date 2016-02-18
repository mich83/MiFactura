class Comprobante
  include Mongoid::Document
  store_in collection: "xml_data"
  field :clave, type: String
  field :data, type: String
end
