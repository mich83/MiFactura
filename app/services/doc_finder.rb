class DocFinder
  def initialize
    @query = Doc
  end

  def find
    @query
  end

  def by_type(type, user_ruc)
    @query = case type
               when :todos
                 @query.any_of({ruc: user_ruc}, {ruc_emisor: user_ruc})
               when :emitidos
                 @query.all_of({ruc_emisor: user_ruc})
               when :recibidos
                 @query.all_of({ruc: user_ruc})
               else
                 @query
             end
    self
  end

  def by_contraparte(type, contraparte_ruc)
    return self if contraparte_ruc.nil?
    @query = case type
               when :emitidos
                 @query.all_of({ruc: contraparte_ruc})
               when :recibidos
                 @query.all_of({ruc_emisor: contraparte_ruc})
               else
                 @query
             end
    self
  end

  def by_doc_type(doc_type)
    return self if doc_type == 0
    @query = @query.all_of({tipo_de_comprobante: doc_type})
    self
  end

  def by_ambiente(ambiente)
    @query = case ambiente
                when :pruebas
                  @query.all_of({:ambiente => "PRUEBAS"})
                when :simulacion
                  @query.all_of({:ambiente => "SIMULACION"})
                else
                  @query.any_of({:ambiente => "PRODUCCIÓN"},{:ambiente => nil})
            end
    self
  end

  def paginate(params)
    @query = @query.desc(:fecha).paginate(:page=>params[:page], :per_page=>10)
    self
  end
end