json.array!(@docs) do |doc|
  json.extract! doc, :id, :clave, :ruc_emisor, :ruc, :razon_social_emisor, :razon_social, :subtotal, :total, :tipo_de_comprobante, :fecha, :direccion, :telefono
  json.url doc_url(doc, format: :json)
end
