
#categoryクラスはApplicationRecordクラスを継承している。つまり、データベースと連携する
class Category < ApplicationRecord
  # Categoryクラスに紐づく情報について。
  # 1つのカテゴリは、複数の取引と紐付き、カテゴリがなくなる時にはnullになる
  has_many :transactions, dependent: :nullify
  #1つのカテゴリは複数のキーワードと紐付き、カテゴリがなくなる時にはそのキーワードも消える
  has_many :category_keywords, dependent: :destroy
  #1つのカテゴリは複数のルールと紐付き、カテゴリがなくなる時にはそのルールも消える
  has_many :category_rules, dependent: :destroy
  
  # カテゴリには条件がある。
  # nameは必須で重複を許さない
  validates :name, presence: true, uniqueness: true
  # colorは必須で、#+6桁のカラーコードで表現される必要がある
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color code" }
  # display_orderは必須で、整数である必要がある
  validates :display_order, presence: true, numericality: { only_integer: true }
  
  # scopeはカテゴリの順番を整えるためのメソッド。deispay_order順かつ、名前順に並ぶ。
  scope :ordered, -> { order(:display_order, :name) }
  
  #transaction_countメソッドは取引数を数える
  def transaction_count
    transactions.count
  end
  
  #total_amountメソッドは取引金額の合計を計算する
  def total_amount
    transactions.sum(:amount)
  end
  
  #keywords_listはカテゴリのキーワードを優先度順に並び替えて、キーワードカラムだけを取り出す。
  def keywords_list
    category_keywords.ordered_by_priority.pluck(:keyword)
  end
end
