class SriController < ApplicationController
  require 'net/http'
  require 'base64'
  require 'xmlsimple'
  skip_before_filter :verify_authenticity_token

  def RecepcionWSDL
    @host = Rails.application.host
    if params[:ambiente] == :pruebas
      @ambiente = 'pruebas'
    elsif params[:ambiente] == :produccion
      @ambiente = 'produccion'
    elsif params[:ambiente] == :simulacion
      @ambiente = 'simulacion'
    end
  end

  def AutorizacionWSDL
    @host = Rails.application.host
    if params[:ambiente] == :pruebas
      @ambiente = 'pruebas'
    elsif params[:ambiente] == :produccion
      @ambiente = 'produccion'
    elsif params[:ambiente] == :simulacion
      @ambiente = 'simulacion'
    end
  end

  def sendComprobante
    data = request.body.read
    req = Hash.from_xml(data.force_encoding("ISO-8859-1"))
    xml_body = req["Envelope"]["Body"][""]
    raw_xml = req["Envelope"]["Body"]["validarComprobante"]["xml"]
    xml = Hash.from_xml(Base64.decode64(raw_xml))
    ruc = clave = xml.values[0]["infoTributaria"]['ruc']
    clave = xml.values[0]["infoTributaria"]['claveAcceso']
    resp_data = nil
    Rails.logger.debug ruc
    user = User.find_by(:RUC=>ruc)
    if params[:ambiente] == :produccion
      if user.nil?
        resp_data = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2=\"http://ec.gob.sri.ws.recepcion\"><RespuestaRecepcionComprobante><estado>DEVUELTA</estado><comprobantes><comprobante><claveAcceso>#{clave}</claveAcceso><mensajes><mensaje><identificador>37</identificador><mensaje>RUC NO FUE ENCONTRADO</mensaje><informacionAdicional>El client no esta registrado</informacionAdicional><tipo>ERROR</tipo></mensaje></mensajes></comprobante></comprobantes></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>"
      else
        if user.apiLimit.nil? || user.apiLimit <= 0
          resp_data = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2=\"http://ec.gob.sri.ws.recepcion\"><RespuestaRecepcionComprobante><estado>DEVUELTA</estado><comprobantes><comprobante><claveAcceso>#{clave}</claveAcceso><mensajes><mensaje><identificador>37</identificador><mensaje>RUC ESTA BLOQUEADO</mensaje><informacionAdicional>El limite de comprobantes esta agotado</informacionAdicional><tipo>ERROR</tipo></mensaje></mensajes></comprobante></comprobantes></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>"
        end
      end
    end
    Rails.logger.debug user.inspect
    if resp_data.nil? && !user.nil?
      begin
        response = querySRI(data, "RecepcionComprobantes",params[:ambiente])
        Rails.logger.debug response.inspect
        if response.instance_of? Net::HTTPOK
          resp_data = response.body.force_encoding("ISO-8859-1").encode("UTF-8")
          resp_xml = Hash.from_xml(resp_data)
          Rails.logger.debug resp_xml.inspect
          if params[:ambiente] == :produccion && resp_xml["Envelope"]["Body"]["validarComprobanteResponse"]["RespuestaRecepcionComprobante"]["estado"] == "RECIBIDA"
            user.apiLimit = user.apiLimit - 1
            user.save
          end
        else
          resp_data = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2=\"http://ec.gob.sri.ws.recepcion\"><RespuestaRecepcionComprobante><estado>DEVUELTA</estado><comprobantes><comprobante><claveAcceso>#{clave}</claveAcceso><mensajes><mensaje><identificador>50</identificador><mensaje>SRI NO DISPONIBLE</mensaje><informacionAdicional>No se puede conectarse al SRI</informacionAdicional><tipo>ERROR</tipo></mensaje></mensajes></comprobante></comprobantes></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>"
        end
      rescue
        resp_data = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2=\"http://ec.gob.sri.ws.recepcion\"><RespuestaRecepcionComprobante><estado>DEVUELTA</estado><comprobantes><comprobante><claveAcceso>#{clave}</claveAcceso><mensajes><mensaje><identificador>50</identificador><mensaje>SRI NO DISPONIBLE</mensaje><informacionAdicional>No se puede conectarse al SRI</informacionAdicional><tipo>ERROR</tipo></mensaje></mensajes></comprobante></comprobantes></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>"
      end
    end
    if resp_data.nil?
      resp_data = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2=\"http://ec.gob.sri.ws.recepcion\"><RespuestaRecepcionComprobante><estado>DEVUELTA</estado><comprobantes><comprobante><claveAcceso>#{clave}</claveAcceso><mensajes><mensaje><identificador>37</identificador><mensaje>RUC NO FUE ENCONTRADO</mensaje><informacionAdicional>El client no esta registrado</informacionAdicional><tipo>ERROR</tipo></mensaje></mensajes></comprobante></comprobantes></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>"
    end
    render :content_type => "text/xml", :body => resp_data.force_encoding("ISO-8859-1")
  end

  def getAutorizacion
    data = request.body.read
    response = querySRI(data, "AutorizacionComprobantes",params[:ambiente])
    if response.instance_of? Net::HTTPOK
      comprobante = SriHelper::SRI.process_response(response.body.force_encoding("ISO-8859-1").encode("UTF-8"))
      if !(comprobante.nil? || comprobante.kind_of?(Symbol))
        doc = Doc.new(comprobante[:comprobante])
        if doc.save
          xml = Comprobante.new(comprobante[:xml])
          xml.save
        end
      end
      render :content_type => "text/xml", :body=> response.body.force_encoding("ISO-8859-1").encode("UTF-8")
    else
      render :status => response.code
    end
  end



  def validarComprobanteSimulacion

    data = request.body.read
    req = Hash.from_xml(data)
    raw_xml = req["Envelope"]["Body"]["validarComprobante"]["xml"]
    xml = Hash.from_xml(Base64.decode64(raw_xml))
    clave = xml.values[0]["infoTributaria"]['claveAcceso']
    doc = Simulados.find_or_create_by clave: clave
    Rails.logger.debug doc.inspect
    if doc.auth.nil?
      doc.text = raw_xml
      doc.auth = KeePass::Password.generate("[d]{37}")
      doc.save
    end
    resp_data = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:validarComprobanteResponse xmlns:ns2="http://ec.gob.sri.ws.recepcion"><RespuestaRecepcionComprobante><estado>RECIBIDA</estado><comprobantes/></RespuestaRecepcionComprobante></ns2:validarComprobanteResponse></soap:Body></soap:Envelope>'
    render :content_type => "text/xml", :body => resp_data
  end


  def processAuthSimulacion
    data = request.body.read
    req = Hash.from_xml(data)
    clave = req['Envelope']['Body']['autorizacionComprobante']['claveAccesoComprobante']
    doc = Simulados.find_by :clave=> clave
    Rails.logger.debug doc.inspect
    resp_data = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ns2:autorizacionComprobanteResponse xmlns:ns2="http://ec.gob.sri.ws.autorizacion"><RespuestaAutorizacionComprobante><claveAccesoConsultada>'
    resp_data+= clave
    resp_data+= '</claveAccesoConsultada>'
    if !doc.nil?
      resp_data += ' <numeroComprobantes>1</numeroComprobantes><autorizaciones><autorizacion><estado>AUTORIZADO</estado><numeroAutorizacion>'
      resp_data += doc.auth
      resp_data += '</numeroAutorizacion><fechaAutorizacion>'
      resp_data += doc.created_at.strftime('%Y-%m-%dT%H:%M:%S.%L%:z')
      resp_data += '</fechaAutorizacion>'
      resp_data += '<ambiente>SIMULACION</ambiente><comprobante><![CDATA['
      resp_data += Base64.decode64(doc.text)
      resp_data += ']]></comprobante>'
      resp_data += '<mensajes><mensaje><identificador>60</identificador><mensaje>ESTE PROCESO FUE REALIZADO EN EL AMBIENTE DE SIMULACION</mensaje><tipo>ADVERTENCIA</tipo></mensaje></mensajes>'
      resp_data += '</autorizacion></autorizaciones>'
    end
    resp_data += ' </RespuestaAutorizacionComprobante></ns2:autorizacionComprobanteResponse></soap:Body></soap:Envelope>'

    comprobante = SriHelper::SRI.process_response(resp_data)
    if !comprobante.nil?
      doc = Doc.new(comprobante[:comprobante])
      if doc.save
        xml = Comprobante.new(comprobante[:xml])
        xml.save
      end
    end


    render :content_type => 'text/xml', :body => resp_data
  end
  private
  def querySRI(data,operation,ambiente)
    if ambiente == :produccion
      uri = URI.parse('https://cel.sri.gob.ec/comprobantes-electronicos-ws/'+operation)
      header = {"User-Agent"=>"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)", "Content-Type"=>"text/xml","SOAPAction"=>"", "Cache-Control"=>"No-Transform", "Host"=>"cel.sri.gob.ec"}
    else
      uri = URI.parse('https://celcer.sri.gob.ec/comprobantes-electronicos-ws/'+operation)
      header = {"User-Agent"=>"Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.0; Trident/5.0)", "Content-Type"=>"text/xml","SOAPAction"=>"", "Cache-Control"=>"No-Transform", "Host"=>"celcer.sri.gob.ec"}
    end
    Rails.logger.debug uri.inspect
    Rails.logger.debug data.inspect
    http = Net::HTTP.new(uri.host,uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.post(uri.path,data,header)
  end
end

