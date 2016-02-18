class Simulados
  include Mongoid::Document
  store_in collection: "simulados"
  field :clave, type: String
  field :auth, type: String
  field :text, type: String
  field :created_at, type: DateTime

  before_create :set_time

  def set_time
    self.created_at = DateTime.now
  end
end
