class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :trackable, :validatable, :omniauthable, omniauth_providers: [:github]

  validates :name, presence: true

  has_many :repositories

  after_create :send_welcome_email

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.github_avatar_url = auth.extra.raw_info.avatar_url
      user.github_username = auth.info.nickname
      user.github_access_token = auth.credentials.token
    end
  end

  private

  def send_welcome_email
    UserNotifier.welcome_email(self).deliver
  end
end
