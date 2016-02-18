module SriHelper
  class SRI
    require 'net/http'
    require 'xmlsimple'
    def self.get_doc_by_clave(clave)
#        client = Savon.client(wsdl: "https://cel.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantes?wsdl")
 #       response = client.call(:autorizacion_comprobante, message: {claveAccesoComprobante: clave})
          if clave[23] == "1"
             uri = URI.parse('https://celcer.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantes')
             header = {"User-Agent"=>"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)", "Content-Type"=>"text/xml","SOAPAction"=>"", "Cache-Control"=>"No-Transform", "Host"=>"celcer.sri.gob.ec"}
          else
            uri = URI.parse('https://cel.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantes')
            header = {"User-Agent"=>"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)", "Content-Type"=>"text/xml","SOAPAction"=>"", "Cache-Control"=>"No-Transform", "Host"=>"cer.sri.gob.ec"}
          end
          Rails.logger.debug uri.inspect

          data = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n <soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\">\n<soap:Body>\n<autorizacionComprobante xmlns=\"http://ec.gob.sri.ws.autorizacion\">\n <claveAccesoComprobante xmlns=\"\">"+clave+"</claveAccesoComprobante>\n</autorizacionComprobante>\n</soap:Body>\n</soap:Envelope>"
          begin
            http = Net::HTTP.new(uri.host,uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            response = http.post(uri.path,data.force_encoding("BINARY"),header)
          rescue
            return :no_disponible
          end
          Rails.logger.debug response.inspect
          if response.instance_of? Net::HTTPOK
            return self.process_response(response.body.force_encoding("ISO-8859-1").encode("UTF-8"))
          else
            return :error_SRI
          end
  end

    def self.process_response(responsebody)
        document = Hash.from_xml(responsebody)

        Rails.logger.debug document.inspect

        begin

          autorizaciones = document["Envelope"]["Body"]["autorizacionComprobanteResponse"]["RespuestaAutorizacionComprobante"]
          if autorizaciones["numeroComprobantes"] == "0"

            return :no_autorizacion
          end

          autorizaciones_array = autorizaciones["autorizaciones"]["autorizacion"]


          process_autorizaciones = Proc.new do |autorizacion|

            if autorizacion["estado"] == "AUTORIZADO"


              result_xml = autorizacion.to_xml(:root=>'autorizacion')
              #result_xml = response.body.force_encoding("ISO-8859-1").encode("UTF-8")

              str_comprobante = autorizacion["comprobante"]
              #comprobante = Hash.from_xml(str_comprobante.force_encoding("ISO-8859-1").encode("UTF-8"))
              comprobante = XmlSimple.xml_in(str_comprobante,KeepRoot: true, SuppressEmpty: true, KeyToSymbol: false, ForceArray: false)
              Rails.logger.debug autorizacion.inspect
              doc = comprobante.values[0]
              infoTributaria = doc["infoTributaria"]

              #infoDoc = doc.values[3]

              result = Hash.new
              result[:clave] = infoTributaria["claveAcceso"]
              result[:tipo_de_comprobante] = infoTributaria["codDoc"]
              result[:ruc_emisor] = infoTributaria["ruc"]
              case result[:tipo_de_comprobante]
                when "01"
                  infoDoc = doc["infoFactura"]
                when "07"
                  infoDoc = doc["infoCompRetencion"]
                when "04"
                  infoDoc = doc["infoNotaCredito"]
                when "06"
                  infoDoc = doc["infoGuiaRemision"]
                else
                  return :unknown_document
              end
              result[:razon_social_emisor] = infoTributaria["razonSocial"]
              if result[:tipo_de_comprobante] == "07"
                result[:ruc] = infoDoc["identificacionSujetoRetenido"]
                result[:razon_social] = infoDoc["razonSocialSujetoRetenido"]
              elsif result[:tipo_de_comprobante] == "06"
                result[:ruc] = infoDoc["rucTransportista"]
                result[:razon_social] = infoDoc["razonSocialTransportista"]
              else
                result[:ruc] = infoDoc["identificacionComprador"]
                result[:razon_social] = infoDoc["razonSocialComprador"]
              end

              result[:subtotal] = infoDoc["totalSinImpuestos"]
              result[:total] = infoDoc["importeTotal"]
              result[:estab] = infoTributaria["estab"]
              result[:ptoEmi] = infoTributaria["ptoEmi"]
              result[:secuencial] = infoTributaria["secuencial"]
              if result[:tipo_de_comprobante] == "06"
                result[:fecha] = infoDoc["fechaIniTransporte"]
              else
                result[:fecha] = infoDoc["fechaEmision"]
              end
              result[:direccion] = infoDoc["dirEstablecimiento"]
              result[:fechaAutorizacion] = autorizacion["fechaAutorizacion"]
              result[:numeroAutorizacion] = autorizacion["numeroAutorizacion"]
              result[:nombreComercial] = infoTributaria["nombreComercial"]
              result[:contribuyenteEspecial] =infoDoc["contribuyenteEspecial"]
              result[:ambiente] = autorizacion["ambiente"]
              if result[:tipo_de_comprobante] == "04"
                result[:codDocModificado] = infoDoc["codDocModificado"]
                result[:numeroDocModificado] = infoDoc["numDocModificado"]
                result[:fechaEmisionDocSustento] = infoDoc["fechaEmisionDocSustento"]
                result[:valorModificacion] = infoDoc["valorModificacion"]
              elsif result[:tipo_de_comprobante] == "06"
                result[:datosGuia] = {:iniTransporte=>infoDoc["fechaIniTransporte"], :finTransporte=>infoDoc["fechaFinTransporte"],:placa=>infoDoc["placa"]}
              end

              if result[:tipo_de_comprobante] == "07"
                procImpuestos = Proc.new do |imp|
                  if imp["valorRetenido"].to_f != 0
                    result[:retenciones].push ({:valor=> imp["valorRetenido"].to_f, :codigo=>imp["codigo"], :porcentaje=>imp["porcentajeRetener"].to_f, :base=>imp["baseImponible"].to_f, :codigoRetencion=>imp["codigoRetencion"], :codDocSustento=>imp["codDocSustento"].to_i, :numDocSustento=>imp["numDocSustento"], :fechaEmisionDocSustento=>imp["fechaEmisionDocSustento"]})
                  end
                end
              elsif result[:tipo_de_comprobante] == "06"
                procImpuestos = Proc.new do |imp|
                  detallesRuta = Array.new
                  procDetallesRuta = Proc.new do |det|
                    detallesRuta.push ({:codigo=>det["codigoInterno"], :descripcion=> det["descripcion"], :cantidad=> det["cantidad"].to_f})
                  end
                  detallesInfo = imp["detalles"]["detalle"]
                  if detallesInfo.kind_of?(Array)
                    detallesInfo.each(&procDetallesRuta)
                  else
                    procDetallesRuta.call(detallesInfo)
                  end
                  result[:destinatarios].push ({:ruc=> imp["identificacionDestinatario"], :razon_social=> imp["razonSocialDestinatario"], :direccion=> imp["dirDestinatario"], :motivo=>imp["motivoTraslado"], :desino=>imp["codEstabDestino"], :ruta=> imp["ruta"], :codDocSustento=> imp["codDocSustento"].to_i, :numDocSustento=>imp["numDocSustento"], :detalles=>detallesRuta})
                end
              else
                procImpuestos = Proc.new do |imp|
                  if imp["valor"].to_f != 0
                    result[:impuestos].push ({:valor=> imp["valor"].to_f, :codigo=>imp["codigo"], :tarifa=>imp["tarifa"], :base=>imp["baseImponible"].to_f})
                  end
                end
              end
                result[:impuestos] = Array.new
                result[:retenciones] = Array.new
                result[:destinatarios] = Array.new
                if result[:tipo_de_comprobante] == "07"
                  totalImpuesto = doc["impuestos"]["impuesto"]
                elsif result[:tipo_de_comprobante] == "06"
                  totalImpuesto = doc["destinatarios"]["destinatario"]
                else
                  Rails.logger.debug infoDoc.inspect
                  totalImpuesto = infoDoc["totalConImpuestos"]["totalImpuesto"]
                end

                #Rails.logger.debug totalImpuesto.inspect
                if !totalImpuesto.nil?
                  if totalImpuesto.kind_of?(Array)
                    totalImpuesto.each(&procImpuestos)
                  else
                    procImpuestos.call(totalImpuesto)
                  end
                end
              begin
                result[:detalles] = Array.new
#                        Rails.logger.debug doc["detalles"].inspect
                procDet = Proc.new do |dt|
                  #Rails.logger.debug dt.inspect
                  detAdicional = Hash.new
                  if dt.has_key?("detallesAdicionales")
                    procAdd = Proc.new do |det|
                      detAdicional[det["nombre"]] = det["valor"]
                    end
                    if dt["detallesAdicionales"]["detAdicional"].kind_of?(Array)
                      dt["detallesAdicionales"]["detAdicional"].each(&procAdd)
                    else
                      procAdd.call(dt["detallesAdicionales"]["detAdicional"])
                    end
                  end
                  Rails.logger.debug detAdicional.inspect
                  result[:detalles].push({:codigo=>dt["codigoPrincipal"], :descripcion=>dt["descripcion"], :cantidad=>dt["cantidad"].to_f,:precio=>dt["precioUnitario"].to_f,:descuento=>dt["descuento"].to_f,:subtotal=>dt["precioTotalSinImpuesto"].to_f, :detalles=>detAdicional})
                end

                det = doc["detalles"]["detalle"]
                if det.kind_of?(Array)
                  det.each(&procDet)
                else
                  procDet.call(det)
                end
              rescue
                result[:detalles] = Array.new
              end
              begin
                infoAdicional = doc["infoAdicional"]
                emails = Array.new
                if !infoAdicional.nil?
                  emailList = ""

                  procInfo = Proc.new do |campo|
                    emailList << ";" if emailList != ""
                    Rails.logger.debug campo.inspect
                    emailList << campo["campoAdicional"]["content"] if campo["campoAdicional"]["nombre"] == "email"
                  end
                  if infoAdicional.kind_of?(Array)
                    infoAdicional.each(&procInfo)
                  else
                    procInfo.call(infoAdicional)
                  end
                  emails = emailList.split(";")

                end
                result[:emailsForNotification] = emails
              rescue
                result[:emailsForNotification] = Array.new
              end


              return {:comprobante => result, :xml => {:clave => result[:clave], :data => result_xml}}
            end
          end
          if autorizaciones_array.kind_of?(Array)
            autorizaciones_array.each(&process_autorizaciones)
          else
            process_autorizaciones.call(autorizaciones_array)
          end

        rescue => e
          Rails.logger.debug "Exception #{e} "+e.backtrace[0]
          return :error_en_documento
        end
        return :no_autorizacion
    end


    def self.send_password(doc)

        user = User.find_by_ruc(doc.ruc)
        Rails.logger.debug user.inspect
        if !user.nil?
          if user.locked
            password = KeePass::Password.generate("[dl]{32}")
            user.unlockcode = password
            if user.save
                mail = Notifier.welcome(user,password)
                Rails.logger.debug mail.inspect
                begin
                  mail.deliver
                rescue => e
                  Rails.logger.debug "Exception #{e} "+e.backtrace[0]
                end
            end
          end
        end
    end

    def self.get_identificacion(ruc)
      if ruc.length == 13
          #es posible que eso es RUC
        if self.check_ruc(ruc)
          return :ruc
        end
      elsif ruc.length == 10
          #es posible que eso es numero de la cedula
        if self.check_cedula(ruc)
          return :cedula
        end
      end
      return :passport
    end

  def self.check_cedula(numero)

      if numero.length != 10
        return false
      end
      if !(numero =~/^\d+$/)
        return false
      end
      if numero[2].to_i > 5
        return false
      end
      verificador = 0
      ver_string = "212121212"
      (0..8).each { |n|
          m = ver_string[n].to_i*numero[n].to_i
          m = m-9 if m >= 10
          verificador = verificador+m
      }
      verificador = 10 - verificador % 10

      return verificador == numero[9].to_i
  end

  def self.check_ruc(numero)
    if !(numero=~/^\d+$/)
      return false
    end
    if numero[-3,3] != "001" || numero.length != 13
      return false
    else
      if numero[2] == "9"
        #Sociedad
        verificador = 0
        ver_string = "432765432"
        (0..8).each { |n|
          verificador = verificador+ver_string[n].to_i*numero[n].to_i
          }
        verificador = 11 - verificador % 11
        return verificador == numero[9].to_i
      elsif numero[2] == "6"
        #Entidad publico
        if numero[9] != "0"
          return false
        end
        ver_string = "32765432"
        verificador = 0
        (0..7).each {|n|
          verificador = verificador+ver_string[n].to_i*numero[n].to_i
        }
        verificador = 11 - verificador % 11
        return verificador == numero[8].to_i
      else
        #Persona natural
          self.check_cedula(numero[0,10])
      end
    end
  end
  end

end
