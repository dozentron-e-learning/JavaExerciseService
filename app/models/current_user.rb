##
# Aus dem Service template von marcel übernommen und angepasst
class CurrentUser
  include ActiveModel::Attributes

  extend Enumerize

  attribute :username
  attribute :first_name
  attribute :last_name
  attribute :email
  attribute :role
  attribute :gildamesh
  attribute :dozentron
  attribute :webmodelica
  attribute :_version

  enumerize :role, in: {student: 10, docent: 80, admin: 100}, default: :student, predicates: true

  def self.build data
    u = CurrentUser.new
    data.each do |k, v|
      u.try("#{k}=".to_sym, v)
    end
    u
  end

  def id
    self.username
  end

  def ==(user)
    user.respond_to? :username and self.username == user.username
  end

  def to_h
    attributes.as_json
  end
end
