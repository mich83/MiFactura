Rails.application.routes.draw do

  get 'api/pruebas/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#RecepcionWSDL', :defaults => { :format => 'xml' }, ambiente: :pruebas

  get 'api/pruebas/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#AutorizacionWSDL', :defaults => {:format=>'xml'}, ambiente: :pruebas

  post 'api/pruebas/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#sendComprobante', :defaults => { :format => 'xml'}, ambiente: :pruebas

  post 'api/pruebas/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#getAutorizacion', :defaults => {:format=>'xml'}, ambiente: :pruebas

  get 'api/produccion/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#RecepcionWSDL', :defaults => { :format => 'xml' }, ambiente: :produccion

  get 'api/produccion/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#AutorizacionWSDL', :defaults => {:format=>'xml'}, ambiente: :produccion

  post 'api/produccion/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#sendComprobante', :defaults => { :format => 'xml'}, ambiente: :produccion

  post 'api/produccion/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#getAutorizacion', :defaults => {:format=>'xml'}, ambiente: :produccion

  get 'api/simulacion/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#RecepcionWSDL', :defaults => { :format => 'xml' }, ambiente: :simulacion

  get 'api/simulacion/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#AutorizacionWSDL', :defaults => {:format=>'xml'}, ambiente: :simulacion

  post 'api/simulacion/comprobantes-electronicos-ws/RecepcionComprobantes' => 'sri#validarComprobanteSimulacion', :defaults => { :format => 'xml'}

  post 'api/simulacion/comprobantes-electronicos-ws/AutorizacionComprobantes' => 'sri#processAuthSimulacion', :defaults => {:format=>'xml'}
  devise_for :users, controllers: { sessions: "custom_devise/sessions", registrations: "custom_devise/registrations" }
  resources :docs, :except=> [:edit, :delete]

  get "/docs/list/:idlist" => "docs#list"

  post '/inbound' => 'docs#inbound'
  get 'welcome/index'

  post '/docs/send' => 'docs#send_email'

  get '/todos', to: "docs#index"
#ambiente de produccion
  get '/recibidos', to: "docs#index", type: :recibidos
  get '/emitidos', to: 'docs#index', type: :emitidos

#  get '/facturas' => 'docs#index', doc_type: 1
#  get '/guias' => 'docs#index', doc_type: 6
#  get '/retenciones' => 'docs#index', doc_type: 7
#  get '/nd' => 'docs#index', doc_type: 5
#  get '/nc' => 'docs#index', doc_type: 4

  get '/recibidos/facturas' => 'docs#index', doc_type: 1, type: :recibidos
  get '/recibidos/guias' => 'docs#index', doc_type: 6, type: :recibidos
  get '/recibidos/retenciones' => 'docs#index', doc_type: 7, type: :recibidos
  get '/recibidos/nd' => 'docs#index', doc_type: 5, type: :recibidos
  get '/recibidos/nc' => 'docs#index', doc_type: 4, type: :recibidos

  get '/emitidos/facturas' => 'docs#index', doc_type: 1, type: :emitidos
  get '/emitidos/guias' => 'docs#index', doc_type: 6, type: :emitidos
  get '/emitidos/retenciones' => 'docs#index', doc_type: 7, type: :emitidos
  get '/emitidos/nd' => 'docs#index', doc_type: 5, type: :emitidos
  get '/emitidos/nc' => 'docs#index', doc_type: 4, type: :emitidos

#ambiente de pruebas

  get '/pruebas/recibidos', to: "docs#index", type: :recibidos, ambiente: :pruebas
  get '/pruebas/emitidos', to: 'docs#index', type: :emitidos, ambiente: :pruebas

  get '/pruebas/facturas' => 'docs#index', doc_type: 1, ambiente: :pruebas
  get '/pruebas/guias' => 'docs#index', doc_type: 6, ambiente: :pruebas
  get '/pruebas/retenciones' => 'docs#index', doc_type: 7, ambiente: :pruebas
  get '/pruebas/nd' => 'docs#index', doc_type: 5, ambiente: :pruebas
  get '/pruebas/nc' => 'docs#index', doc_type: 4, ambiente: :pruebas

  get '/pruebas/recibidos/facturas' => 'docs#index', doc_type: 1, type: :recibidos, ambiente: :pruebas
  get '/pruebas/recibidos/guias' => 'docs#index', doc_type: 6, type: :recibidos, ambiente: :pruebas
  get '/pruebas/recibidos/retenciones' => 'docs#index', doc_type: 7, type: :recibidos, ambiente: :pruebas
  get '/pruebas/recibidos/nd' => 'docs#index', doc_type: 5, type: :recibidos, ambiente: :pruebas
  get '/pruebas/recibidos/nc' => 'docs#index', doc_type: 4, type: :recibidos, ambiente: :pruebas

  get '/pruebas/emitidos/facturas' => 'docs#index', doc_type: 1, type: :emitidos, ambiente: :pruebas
  get '/pruebas/emitidos/guias' => 'docs#index', doc_type: 6, type: :emitidos, ambiente: :pruebas
  get '/pruebas/emitidos/retenciones' => 'docs#index', doc_type: 7, type: :emitidos, ambiente: :pruebas
  get '/pruebas/emitidos/nd' => 'docs#index', doc_type: 5, type: :emitidos, ambiente: :pruebas
  get '/pruebas/emitidos/nc' => 'docs#index', doc_type: 4, type: :emitidos, ambiente: :pruebas

# ambiente de simulacion
  get '/simulacion/recibidos', to: "docs#index", type: :recibidos, ambiente: :simulacion
  get '/simulacion/emitidos', to: 'docs#index', type: :emitidos, ambiente: :simulacion

  get '/simulacion/facturas' => 'docs#index', doc_type: 1, ambiente: :simulacion
  get '/simulacion/guias' => 'docs#index', doc_type: 6, ambiente: :simulacion
  get '/simulacion/retenciones' => 'docs#index', doc_type: 7, ambiente: :simulacion
  get '/simulacion/nd' => 'docs#index', doc_type: 5, ambiente: :simulacion
  get '/simulacion/nc' => 'docs#index', doc_type: 4, ambiente: :simulacion

  get '/simulacion/recibidos/facturas' => 'docs#index', doc_type: 1, type: :recibidos, ambiente: :simulacion
  get '/simulacion/recibidos/guias' => 'docs#index', doc_type: 6, type: :recibidos, ambiente: :simulacion
  get '/simulacion/recibidos/retenciones' => 'docs#index', doc_type: 7, type: :recibidos, ambiente: :simulacion
  get '/simulacion/recibidos/nd' => 'docs#index', doc_type: 5, type: :recibidos, ambiente: :simulacion
  get '/simulacion/recibidos/nc' => 'docs#index', doc_type: 4, type: :recibidos, ambiente: :simulacion

  get '/simulacion/emitidos/facturas' => 'docs#index', doc_type: 1, type: :emitidos, ambiente: :simulacion
  get '/simulacion/emitidos/guias' => 'docs#index', doc_type: 6, type: :emitidos, ambiente: :simulacion
  get '/simulacion/emitidos/retenciones' => 'docs#index', doc_type: 7, type: :emitidos, ambiente: :simulacion
  get '/simulacion/emitidos/nd' => 'docs#index', doc_type: 5, type: :emitidos, ambiente: :simulacion
  get '/simulacion/emitidos/nc' => 'docs#index', doc_type: 4, type: :emitidos, ambiente: :simulacion

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  get "/faq" => 'welcome#faq'

  get "/api" => 'welcome#api'

  get '/stat' => 'welcome#stat'

  get "/seguridad" => 'welcome#seguridad'

  get "/capacitaciones" => 'welcome#capacitaciones'

  #get 'activate/:id/:code' => "custom_devise/sessions#activate"

  devise_scope :user do
    get "/activate/:id/:code" => "custom_devise/sessions#activate"
  end
#  post 'docs' =>'docs#find_or_create_by_clave'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
