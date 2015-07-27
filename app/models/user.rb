class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  acts_as_messageable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  has_many :orders, foreign_key: "selector_id"
  has_many :selected_leads, through: :orders, source: :selected
  has_many :leads, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :likes, as: :likeable

  has_attached_file :picture, :styles => { :medium => "300x300>", :thumb => "100x100>" }, :default_url => "/images/:style/missing.png"
  validates_attachment_size :picture, less_than: 1.megabytes
  validates_attachment_content_type :picture, content_type: ["image/jpeg", "image/png", "image/jpg", "image/bmp"]
  validates :picture_file_name, length: { maximum: 150 }



   # #############################################################################
  # Order between User and Lead
  # #############################################################################
  def selecting?(one_lead)
    orders.find_by_selected_id(one_lead.id)
  end

  def select!(one_lead)
    orders.create!(selected_id: one_lead.id)
  end

   # #############################################################################
  # Like // User and Project
  # #############################################################################
  def liking?(one_project)
    self.likes.find_by_likeable_id(one_project.id)
  end

  def like!(one_project)
    self.likes.create!(likee_id: one_project.id)
  end

  private

#Mailboxer

  def name
    email
  end

  def mailboxer_email(object)
    email
  end

  def self.search_by_id(search)
    where('users.id LIKE ?', "%#{search}%")
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.first_name = auth.info.name
      user.password = Devise.friendly_token[0,20]
    end
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.github_data"] && session["devise.github_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

end