# APIのバージョン1のカテゴリデータ管理を行うコントローラークラスを定義する
# ApplicationControllerクラスから継承し、共通機能を利用する
class Api::V1::CategoriesController < ApplicationController
  # カテゴリ一覧を取得するアクションメソッドを定義する
  def index
    # 現在は空の実装：将来的にカテゴリデータの取得処理を実装予定
  end
# コントローラークラスの終了
end
