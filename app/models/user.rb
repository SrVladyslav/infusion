class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  has_many :identities, dependent: :destroy

  has_many :proposals

  has_many :votes
  has_many :interests, through: :votes, source: :proposal

  has_many :holdings
  has_many :meetups, through: :holdings, as: :keynotes

  has_many :assistances
  has_many :meetups, through: :assistances

  has_one :role

  has_attached_file :avatar
  validates_attachment_content_type :avatar, content_type: /\Aimage/

  def admin?
    role_id == Role.find_by_name('Admin')
  end

  attr_accessor :login

  def self.create_with_omniauth(auth)
    email = auth[:info][:email] || 'change@me.please'
    username = auth[:info][:nickname] || self.generate_username(auth[:info][:name])
    if self.find_by_username(username)
      name = username + '_' + auth[:provider]
    else
      name = username
    end

    create(email: email, username: name, password: Devise.friendly_token[0,20], role_id: 1)
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      if conditions[:username].nil?
        where(conditions).first
      else
        where(username: conditions[:username]).first
      end
    end
  end

  def self.generate_username(fullname)
    ActiveSupport::Inflector.transliterate(fullname)
      .downcase.strip
      .gsub(/[^a-z]/, '_')
      .gsub(/\A_+/, '')
      .gsub(/_+\Z/, '')
      .gsub(/_+/, '_')
  end

end
