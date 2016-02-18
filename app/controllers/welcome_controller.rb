class WelcomeController < ApplicationController
  def index
    @buttons = [{:caption=>"Consultar por clave", :info=>"verifique la factura por la clave del RIDE", :button=>"Cosultar", :img=>"1page_img1"}, {:caption=>"Subir archivo", :info=>"visualice el detalle del archivo XML", :button=>"Subir", :img=>"1page_img2"}]

      if user_signed_in?
        @buttons << {:caption=>"Mis facturas",:info=>"recibidas",:button=>"Ver",:img=>"1page_img3", :ref=>'/recibidos/facturas'}
      else
        @buttons << {:caption=>"Registrar RUC",:info=>"registrese en el sistema",:button=>"Registrar",:img=>"1page_img3"}
      end
  end

  def faq
  end

  def api

  end

  def seguridad

  end

  def capacitaciones
    redirect_to "http://its.abaco.com.ec/pages/viewpage.action?pageId=6291545"
  end

  def stat
    doc_stat = Doc.collection.aggregate("$group" => { "_id" => {"tipo"=>"$tipo_de_comprobante", "ambiente"=>"$ambiente"}, count: {"$sum" =>  1} })
    @tipos = Hash.new
    doc_stat.each do |elem|
      ambiente = elem["_id"]["ambiente"]
      tipo = Doc.tipo_de_comprobante_s(elem["_id"]["tipo"])
      if @tipos[ambiente].nil?
        @tipos[ambiente] = {:count => 0, :tipos => Array.new}
      end
      @tipos[ambiente][:count] += elem[:count]
      @tipos[ambiente][:tipos] << {:tipo => tipo, :count=>elem["count"]}
    end

    Rails.logger.debug doc_stat.inspect
  end
end
