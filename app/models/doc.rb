class Doc
  include Mongoid::Document
  store_in collection: "comprobantes"
  field :clave, type: String
  field :ruc_emisor, type: String
  field :ruc, type: String
  field :razon_social_emisor, type: String
  field :razon_social, type: String
  field :subtotal, type: Float
  field :total, type: Float
  field :tipo_de_comprobante, type: Integer
  field :fecha, type: DateTime
  field :direccion, type: String
  field :telefono, type: String
  field :estab, type:String
  field :ptoEmi, type:String
  field :secuencial, type:String
  field :detalles, type:Array
  field :nombreComercial, type:String
  field :fechaAutorizacion, type:DateTime
  field :contribuyenteEspecial, type:String
  field :numeroAutorizacion, type:String
  field :impuestos, type:Array
  field :retenciones, type:Array
  field :destinatarios, type:Array
  field :ambiente, type:String

  field :codDocModificado, type:Integer
  field :numeroDocModificado, type:String
  field :fechaEmisionDocSustento, type:DateTime
  field :valorModificacion, type:Float
  field :datosGuia, type:Hash

  field :periodoFiscal, type:String
  field :emailsForNotification, type:Array


  before_save :check_ruc
  before_save :check_clave

  after_save :notify


  def tipo_de_comprobante_s
    Doc.tipo_de_comprobante_s(tipo_de_comprobante)
  end

  def self.tipo_de_comprobante_s(tipo_de_comprobante)
    case tipo_de_comprobante
      when 1
        "Factura"
      when 4
        "Nota de credito"
      when 5
        "Nota de debito"
      when 6
        "Guia de remision"
      when 7
        "Comprobante de retencion"
      else
        "Documento indefinido"
    end
  end

  def numero
    estab+"-"+ptoEmi+"-"+secuencial
  end

  def impuestos_info

    if impuestos.nil?
      return Array.new
    end
    impuestos.map {|x|
      case x[:codigo]
        when "2"
          {:descr => "IVA", :valor=> x[:valor]}
        when "3"
          {:descr => "ICE", :valor=> x[:valor]}
        else
          {:descr => "Impuesto indefenido", :valor=> x[:valor]}
      end
    }
  end

  def notify
    if !self.emailsForNotification.nil?
      self.emailsForNotification.each { |email|
        mail = Notifier.document(email,self,self.tipo_de_comprobante_s+" #"+self.numero+' de '+self.fecha.to_s(:default))
        begin
          mail.deliver
        rescue => e
          Rails.logger.debug "Exception #{e} "+e.backtrace[0]
        end
         }
    end
  end

  private

  def check_ruc
    if !self.ruc.nil? && SriHelper::SRI.get_identificacion(self.ruc) == :passport
      self.ruc.gsub!(/^0+/, '')
    end
    if !self.ruc_emisor.nil? && SriHelper::SRI.get_identificacion(self.ruc_emisor) == :passport
      self.ruc_emisor.gsub!(/^0+/,'')
    end
  end

  def check_clave
    doc = Doc.find_by clave: self.clave
    doc.nil?
  end
end
