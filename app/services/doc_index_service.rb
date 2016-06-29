class DocIndexService
  def initialize(current_user, params)
    @params = params
    @doc_type = doc_type
    @current_user  = current_user
    @ambiente_description = ambiente_description[param(:ambiente)]
    @doc_description = doc_description[param(:doc_type)]
  end

  def search
    {
        ambiente_path: ambiente_path,
        ambiente: ambiente,
        title: title,
        path_prefix: path_prefix,
        path_postfix: path_postfix,
        doc_type: doc_type,
        type_caption: type_caption,
        user_ruc: @current_user.RUC,
        contraparte: param(:contraparte),
        docs: find_docs,
        only_recibidos: @current_user.apiLimit.nil?,
        only_produccion: @current_user.apiLimit.nil?
    }
  end


  private

  def param(name)
    @params.has_key?(name) ? @params[name] : default_values[name]
  end

  def value(source, key, default_value)
    source.nil? ? default_value : source[key]
  end

  def default_values
    {
        ambiente: :produccion,
        type: :recibidos,
        doc_type: 0
    }
  end

  def ambiente_description
    {
        pruebas:    {name: 'Pruebas',    path: '/pruebas'},
        simulacion: {name: 'Simulacion', path: '/simulacion'},
        produccion: {name: 'Produccion', path: ''}
    }
  end

  def doc_description
    {
      1 => {id: 1, path: '/facturas',    description: 'Facturas'},
      4 => {id: 4, path: '/nc',          description: 'Notas de credito'},
      5 => {id: 5, path: '/nd',          description: 'Notas de debito'},
      6 => {id: 6, path: '/guias',       description: 'Guias de remision'},
      7 => {id: 7, path: '/retenciones', description: 'Comprobantes de retencion'},
      0 => {id: 0, path: '',             description: 'Todos'}
    }
  end

  def ambiente_path
    value(@ambiente_description, :path, '')
  end

  def ambiente
    value(@ambiente_description, :name, '')
  end

  def title
    'Facturas @ '
  end

  def path_postfix
    "/#{param(:type)}"
  end

  def path_prefix
    value(@doc_description, :path, '')
  end

  def doc_type
    value(@doc_description, :id, 0)
  end

  def type_caption
    value(@doc_description, :description, '')
  end

  def find_docs
    DocFinder.new
             .by_type(param(:type), @current_user.RUC)
             .by_contraparte(param(:type), param(:contraparte))
             .by_doc_type(doc_type)
             .by_ambiente(param(:ambiente))
             .paginate(@params)
             .find
  end

end