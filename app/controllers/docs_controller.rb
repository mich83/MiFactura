class DocsController < ApplicationController
  before_action :set_doc, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:inbound]

  # GET /docs
  # GET /docs.json
  def index
    if user_signed_in?
        doc_service = DocIndexService.new(current_user, params)
        view_init doc_service.search
    else
      redirect_to "/", :alert => "Para ver los documentos por favor <a data-toggle=\"modal\" data-target=\"#loginModal\">registrese</a> en el sistema"
    end
  end

  # GET /docs/1
  # GET /docs/1.json
  def show

    @title = " #{@doc.tipo_de_comprobante_s} # #{@doc.numero} de #{@doc.fecha.to_s(:default)} @ "

    if @doc.nil?
      redirect_to "/"
    else
      if @doc.ambiente == "PRUEBAS"
        flash[:notice] = "El documento está emitido en ambiente de pruebas. El documento no tiene valor fiscal!"
      elsif @doc.ambiente == "SIMULACION"
        flash[:error] = "ATTENCIÓN! El documento no fue autorizado por el SRI. Hecho en ambiente de simulación"
      end
      if @doc.emailsForNotification.nil?
        @correo_principal = ""
      else
        @correo_principal = @doc.emailsForNotification[0]
      end
      respond_to do |format|
        format.html #
        format.xml {
          comprobante = Comprobante.find_by(clave: @doc.clave)
          if (!comprobante.nil?)
            send_data comprobante.data,  :type => "text/xml", :filename => @doc.numero+".xml"
          end
        }
      end
    end
  end

  # GET /docs/new
  def new
    @doc = Doc.new
  end

  def list
    ids = params[:idlist]
    @docs = ids.split("-").map { |id| Doc.find(id)}
  end
  # GET /docs/1/edit
#  def edit
#  end

  # POST /docs
  # POST /docs.json
  def create
    #@doc = Doc.new(doc_params)

    #respond_to do |format|
    #  if @doc.save
    #    format.html { redirect_to @doc, notice: 'Doc was successfully created.' }
    #    format.json { render :show, status: :created, location: @doc }
    #  else
    #    format.html { render :new }
    #    format.json { render json: @doc.errors, status: :unprocessable_entity }
    #  end
    #end

    filtered_params = doc_params

    clave = nil

    if filtered_params[:clave].nil?
      if !filtered_params[:archivo].nil?
        file = filtered_params[:archivo]
        clave = get_clave_from_file(file)
        if clave.nil?
          redirect_to "/", alert: "Parece que el formato del archivo no es comprobante electrónico. Si usted esta seguro que el formato está correcto, por favor envíe el documento al soporte@abaco.com.ec para la revisión."
          return
        end
      end
     else
      clave = filtered_params[:clave].strip
    end
    if clave.nil?
      redirect_to "/", notice: "La clave no está encontrada"
      return
    end
    if clave.kind_of?(Array)
      docs = clave.map {|clave_doc| search_document(clave_doc)}
      alert = ""
      url = ""
      docs.each { |doc|
        if doc.kind_of?(Doc)
          url = url + (url=="" ? "" : "-") + doc._id
        else
          alert = alert + (alert = "" ? "" : "<br>") + doc.to_s
        end
      }
        if url == ""
          url = "/"
        else
          url = "/docs/list/"+url
        end
        Rails.logger.debug url.inspect
        if alert == ""
          redirect_to url
        else
          redirect_to url, alert: alert
        end

      return
    else
      @doc = search_document(clave)
      if @doc.kind_of?(String)
        redirect_to "/", alert: @doc
        return
      end
    end

    if !@doc.nil?
      Rails.logger.debug "Send password"
      SriHelper::SRI.send_password(@doc)
      respond_to do |format|
        format.html { redirect_to @doc }
        format.json { render :show, status: :created, location: @doc }
      end
    else
      redirect_to "/", notice: :error
    end
  end

  # PATCH/PUT /docs/1
  # PATCH/PUT /docs/1.json
  def update
    respond_to do |format|
      if @doc.update(doc_params)
        format.html { redirect_to @doc, notice: "El documento está actualizado con exito" }
        format.json { render :show, status: :ok, location: @doc }
      else
        format.html { render :edit }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docs/1
  # DELETE /docs/1.json
  def destroy
    @doc.destroy
    respond_to do |format|
      format.html { redirect_to docs_url, notice: "El documento está elimninado con exito" }
      format.json { head :no_content }
    end
  end



  def inbound
    sender = params["sender"]
    att_count = params["attachment-count"].to_i
    (1..att_count).each do |n|
      file = params["attachment-#{n}"]
      claves = get_clave_from_file(file)

      process_clave = Proc.new do |clave|
        doc = Doc.find_by(clave: clave)
        if (doc.nil?)
          comprobante = SriHelper::SRI.get_doc_by_clave(clave)
          if !(comprobante.nil? || comprobante.kind_of?(Symbol))
            doc = Doc.new(comprobante[:comprobante])
            if doc.save
              xml = Comprobante.new(comprobante[:xml])
              xml.save
            end
          end
        end
        if !doc.nil?
          send_document(doc)
        end
      end
      if !claves.nil?
        if claves.kind_of?(Array)
          claves.each(&process_clave)
        else
          process_clave.call(claves)
        end
      end
    end
    render :status => 200, :content_type => 'text/html', :body => "OK"
  end

  def send_email
      doc = Doc.find(params[:id])
      if doc.nil?
        redirect_to "/", alert: "El documento no está encontrado"
      else
        send_document(doc, params[:address])
        redirect_to url_for(doc)
      end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doc
      @doc = Doc.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def doc_params
      params.permit(:clave, :archivo)
    end

    def get_clave_from_file(file)
      xml_content = nil
      Rails.logger.debug file.content_type
      if file.content_type=~/^application\/\S*zip/ || file.content_type == 'application/octet-stream'
        begin
          list = Array.new
          Zip::ZipFile.open(file.tempfile.path) do |zipfile|
            zipfile.each do |entry|
              Rails.logger.debug entry.name
              if entry.name.downcase=~/\.xml/
                clave = clave_from_xml(entry.get_input_stream.read)
                if !clave.nil?
                  list << clave
                end
              end
            end
          end
          if list.length == 0
            return nil
          elsif list.length == 1
            return list[0]
          else
            return list
          end
        rescue
            return nil
        end
      else
        if file.content_type == "text/xml" || file.content_type == "application/xml"
          xml_content = File.open(file.tempfile.path).read
          return clave_from_xml(xml_content)
        end
      end
      return nil
    end

    def clave_from_xml(xml_content)
      clave = /claveAcceso(\>|&gt;)(\d{49})/.match(xml_content)
      if clave.nil?
        return nil
      else
        return clave[2]
      end
    end

    def send_factura(address, doc, caption)
      mail = Notifier.document(address,doc, caption)
      begin
        mail.deliver
      rescue => e
        Rails.logger.debug "Exception #{e} "+e.backtrace[0]
      end
    end

  def search_document(clave)
    doc = Doc.find_by(clave: clave)

    if (doc.nil?)

      comprobante = SriHelper::SRI.get_doc_by_clave(clave)
      if (comprobante.nil? || comprobante.kind_of?(Symbol))
        case comprobante
          when :error_en_documento
            return "La estructura de documento con la clave #{clave} no cumple las reglas"
          when :no_autorizacion
            return "El documento con la clave #{clave} no fue encontrado"
          when :no_disponible
            return "El servicio de SRI no está disponible"
          when :error_SRI
            return "El error ocurrió en el servidor de SRI"
          else
            return "Ocurrió el error desconocido durante la búsqueda de documento con la clave #{clave}"
        end
    else
        doc = Doc.new(comprobante[:comprobante])
        if !doc.save
          return "El error ocrrrió durante grabación de documento"
        end
        xml = Comprobante.new(comprobante[:xml])
        xml.save
      end
    end
    return doc

  end


  def send_document(doc, email=nil)
    emisor = User.find_by(RUC: doc.ruc_emisor)
    comprador = User.find_by(RUC: doc.ruc)
    if email.nil?
      if emisor.nil? && comprador.nil?
        send_factura(sender, doc, " #{doc.tipo_de_comprobante_s} ##{doc.numero} de #{doc.fecha.to_s(:default)}")
      else
        if !emisor.nil?
          send_factura(emisor.email, doc, " #{doc.tipo_de_comprobante_s} emitida ##{doc.numero} de #{doc.fecha.to_s(:default)}")
        end
        if !comprador.nil?
          send_factura(comprador.email, doc, " #{doc.tipo_de_comprobante_s} recibida ##{doc.numero} de #{doc.fecha.to_s(:default)}")
        end
      end
    else
      send_factura(email, doc, " #{doc.tipo_de_comprobante_s} ##{doc.numero} de #{doc.fecha.to_s(:default)}")
    end
  end
end
