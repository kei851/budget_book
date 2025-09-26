# APIのバージョン1の取引データ管理を行うコントローラークラスを定義する
# ApplicationControllerクラスから継承し、共通機能を利用する
class Api::V1::TransactionsController < ApplicationController
  # updateアクション実行前にset_transactionメソッドを呼び出し、対象の取引データを取得する
  before_action :set_transaction, only: [:update]

  # 取引データ一覧を取得するアクションメソッドを定義する
  def index
    # Transactionモデルから全ての取引データを取得し、関連するカテゴリ情報も含めてN+1問題を回避する
    # 取引日付の降順で並び替えて最新のデータから表示する
    @transactions = Transaction.includes(:category).order(transaction_date: :desc)
    
    # 月次フィルタリング処理：パラメータで月が指定されている場合のみ実行する
    if params[:month].present?
      # 指定された年月文字列（YYYY-MM形式）の1日を開始日として設定する
      start_date = Date.parse("#{params[:month]}-01")
      # 開始日と同じ月の最終日を終了日として設定する
      end_date = start_date.end_of_month
      # 指定された月の期間内の取引データのみに絞り込む
      @transactions = @transactions.where(transaction_date: start_date..end_date)
    end
    
    # カテゴリフィルタリング処理：パラメータでカテゴリIDが指定されている場合のみ実行する
    if params[:category_id].present?
      # 指定されたカテゴリIDに一致する取引データのみに絞り込む
      @transactions = @transactions.where(category_id: params[:category_id])
    end
    
    # ページネーション処理：大量データの表示パフォーマンス向上のため
    # リクエストパラメータからページ番号を取得し、未指定の場合は1ページ目を設定する
    page = params[:page] || 1
    # リクエストパラメータから1ページあたりの表示件数を取得し、未指定の場合は50件を設定する
    per_page = params[:per_page] || 50
    # Kaminarigemを使用してページネーション処理を適用する
    @transactions = @transactions.page(page).per(per_page)
    
    # JSON形式でレスポンスデータを構築し、フロントエンドに返却する
    render json: {
      # 取引データ配列：カテゴリ情報を含めてJSON形式に変換する
      transactions: @transactions.as_json(include: :category),
      # ページネーション情報：フィルタリング後の全件数
      total_count: @transactions.total_count,
      # ページネーション情報：現在表示中のページ番号
      current_page: @transactions.current_page,
      # ページネーション情報：全ページ数
      total_pages: @transactions.total_pages
    }
  end

  # 既存の取引データを更新するアクションメソッドを定義する
  def update
    # before_actionで取得した@transactionに対してパラメータで受け取った値を更新する
    if @transaction.update(transaction_params)
      # 更新が成功した場合、更新後の取引データをカテゴリ情報と共にJSON形式で返却する
      render json: @transaction.as_json(include: :category)
    else
      # 更新が失敗した場合、バリデーションエラーメッセージを含むエラーレスポンスを返却する
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # CSVファイルから取引データをインポートするアクションメソッドを定義する
  def import
    # CSVファイルパラメータが存在しない場合はエラーレスポンスを返却する
    unless params[:csv_file].present?
      # 400 Bad Requestステータスでエラーメッセージを返却する
      render json: { error: 'CSVファイルが選択されていません' }, status: :bad_request
      # メソッドの実行を終了する
      return
    end

    # 例外処理ブロック：インポート処理中のエラーをキャッチする
    begin
      # インポート開始をログに記録する（ファイル名を含む）
      Rails.logger.info "CSV Import Started: #{params[:csv_file].original_filename}"
      
      # 既存データクリアオプション：パラメータがtrueの場合のみ実行する
      # 全ての既存取引データを削除する
      Transaction.delete_all if params[:clear_existing] == 'true'
      
      # アップロード履歴レコードを新規作成する
      upload_history = UploadHistory.create!(
        # アップロードされたファイルの元のファイル名を保存する
        filename: params[:csv_file].original_filename,
        # 現在の日時をアップロード日時として保存する
        upload_date: Time.current,
        # ファイル内容のMD5ハッシュ値を計算して重複チェック用に保存する
        file_hash: Digest::MD5.hexdigest(params[:csv_file].read)
      )
      
      # ファイル読み込み位置を先頭にリセットする（ハッシュ計算で末尾まで読んだため）
      params[:csv_file].rewind
      
      # CSVインポート処理を実行するサービスクラスのインスタンスを生成する
      import_service = CsvImportService.new(params[:csv_file], upload_history)
      # インポート処理を実行し、結果を取得する
      result = import_service.import
      
      # インポート結果をログに記録する
      Rails.logger.info "CSV Import Result: #{result.inspect}"
      
      # インポートが成功した場合またはインポート件数が1件以上の場合の処理
      if result[:success] || result[:imported_count] > 0
        # アップロード履歴にインポート件数を更新する
        upload_history.update!(imported_count: result[:imported_count])
        
        # 成功レスポンスをJSON形式で返却する
        render json: {
          # インポート完了メッセージ
          message: 'CSVインポートが完了しました',
          # 実際にインポートされた件数
          imported_count: result[:imported_count],
          # CSVファイルの総行数
          total_rows: result[:total_rows],
          # インポート中に発生したエラー情報
          errors: result[:errors],
          # 作成されたアップロード履歴のID
          upload_history_id: upload_history.id
        }
      else
        # インポートが完全に失敗した場合のエラーログ出力
        Rails.logger.error "CSV Import Failed: #{result[:errors]}"
        # 422 Unprocessable Entityステータスでエラーレスポンスを返却する
        render json: {
          # エラーメッセージ
          error: 'CSVインポートに失敗しました',
          # 詳細なエラー情報
          errors: result[:errors]
        }, status: :unprocessable_entity
      end
    # 予期しない例外をキャッチする
    rescue => e
      # エラー詳細とスタックトレースをログに記録する
      Rails.logger.error "Import Error: #{e.message}\n#{e.backtrace.join("\n")}"
      # 500 Internal Server Errorステータスでエラーレスポンスを返却する
      render json: { error: "インポート処理中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
    end
  end

  # 月次集計データを取得するアクションメソッドを定義する
  def monthly
    # 取引データを関連するカテゴリ情報と共に取得してN+1問題を回避する
    transactions = Transaction.includes(:category)
    
    # 年月パラメータが両方指定されている場合の期間フィルタリング処理
    if params[:year] && params[:month]
      # 指定された年月の1日を開始日として設定する
      start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
      # 開始日と同じ月の最終日を終了日として設定する
      end_date = start_date.end_of_month
      # 指定された月の期間内の取引データのみに絞り込む
      transactions = transactions.where(transaction_date: start_date..end_date)
    end
    
    # カテゴリ別の支出合計を集計する処理
    # カテゴリテーブルとJOINしてカテゴリ名と色で分類し、金額を合計する
    category_totals = transactions.joins(:category)
                                .group('categories.name', 'categories.color')
                                .sum(:amount)
    
    # 月別推移データを集計する処理
    # Groupdategemを使用して取引日付を月単位でグループ化し、金額を合計する
    monthly_totals = transactions.group_by_month(:transaction_date)
                               .sum(:amount)
    
    # JSON形式でレスポンスデータを構築し、フロントエンドに返却する
    render json: {
      # カテゴリ別集計：配列形式に変換してカテゴリ名、色、合計を含める
      category_totals: category_totals.map { |k, v| { category: k[0], color: k[1], total: v } },
      # 月別推移データ：日付をキー、合計金額を値とするハッシュ
      monthly_totals: monthly_totals,
      # 期間内の総支出金額
      total_amount: transactions.sum(:amount),
      # 期間内の取引総件数
      transaction_count: transactions.count
    }
  end

  # 詳細な分析データを取得するアクションメソッドを定義する
  def analytics
    # 取引データを関連するカテゴリ情報と共に取得してN+1問題を回避する
    transactions = Transaction.includes(:category)
    
    # 開始日と終了日のパラメータが両方指定されている場合の期間フィルタリング処理
    if params[:start_date] && params[:end_date]
      # 文字列パラメータをDateオブジェクトに変換して開始日を設定する
      start_date = Date.parse(params[:start_date])
      # 文字列パラメータをDateオブジェクトに変換して終了日を設定する
      end_date = Date.parse(params[:end_date])
      # 指定された期間内の取引データのみに絞り込む
      transactions = transactions.where(transaction_date: start_date..end_date)
    else
      # 期間パラメータが指定されていない場合は全期間のデータを対象とする
      # transactions = transactions (期間制限を行わないためコメントアウト)
    end
    
    # カテゴリ別月別の統計データを集計する処理
    # カテゴリテーブルとJOINし、カテゴリ名、色、月で分類して金額を合計する
    category_stats = transactions.joins(:category)
                               .group('categories.name', 'categories.color')
                               .group_by_month(:transaction_date)
                               .sum(:amount)
    
    # 日別の支出合計を集計する処理
    # Groupdategemを使用して取引日付を日単位でグループ化し、金額を合計する
    daily_totals = transactions.group_by_day(:transaction_date)
                             .sum(:amount)
    
    # 支出金額が高い上位10店舗を特定する処理
    # 店舗名でグループ化して金額を合計する
    top_stores = transactions.group(:store_name)
                           # 店舗別の総支出金額を合計する
                           .sum(:amount)
                           # 支出金額の降順でソートする
                           .sort_by { |_, total| -total }
                           # 上位10店舗のみを取得する
                           .first(10)
    
    # JSON形式でレスポンスデータを構築し、フロントエンドに返却する
    render json: {
      # カテゴリ別統計：format_category_statsメソッドでフロントエンド用に整形する
      category_stats: format_category_stats(category_stats),
      # 日別集計：日付をキー、合計金額を値とするハッシュ
      daily_totals: daily_totals,
      # 上位支出店舗：配列形式に変換して店舗名と合計を含める
      top_stores: top_stores.map { |store, total| { store: store, total: total } },
      # 期間内の総支出金額
      total_amount: transactions.sum(:amount),
      # 日平均支出金額：総金額を取引があった日数で割って算出する（ゼロ除算回避で最小値を1に設定）
      average_daily: transactions.sum(:amount) / [transactions.group_by_day(:transaction_date).count.size, 1].max
    }
  end

  # privateメソッド群の開始：コントローラ内部でのみ使用されるメソッドを定義する
  private

  # before_actionで呼び出されるメソッド：パラメータIDから対象の取引データを取得する
  def set_transaction
    # パラメータIDを使用してデータベースから該当の取引データを取得し、インスタンス変数に保存する
    @transaction = Transaction.find(params[:id])
  end

  # Strong Parameters：フロントエンドから送信されたパラメータのホワイトリストを定義する
  def transaction_params
    # transactionキーが必須で、指定したフィールドのみを許可してセキュリティを確保する
    params.require(:transaction).permit(:category_id, :store_name, :amount, :transaction_date)
  end

  # カテゴリ別統計データをフロントエンド用の形式に整形するプライベートメソッド
  def format_category_stats(stats)
    # カテゴリ別にデータをグループ化するための空のハッシュを初期化する
    grouped = {}
    # 集計された統計データをループで処理し、カテゴリ別にグループ化する
    stats.each do |key, value|
      # キーからカテゴリ名、色、日付情報を分解して取得する
      category, color, date = key
      # カテゴリがまだ初期化されていない場合は新しいハッシュで初期化する
      grouped[category] ||= { name: category, color: color, monthly_data: {}, total: 0, count: 0 }
      # 指定された日付に対する金額データを設定する（nilの場合は0を設定）
      grouped[category][:monthly_data][date] = value || 0
      # カテゴリの総合計に金額を加算する（nilの場合は0を加算）
      grouped[category][:total] += (value || 0)
    end
    
    # カテゴリ別の取引件数を別途集計してデータに追加する
    # トランザクションテーブルとカテゴリテーブルをJOINしてカテゴリ名でグループ化し、件数を集計する
    category_counts = Transaction.joins(:category).group('categories.name').count
    # グループ化したデータをループで処理し、件数とID情報を追加する
    grouped.each do |category_name, data|
      # 該当カテゴリの取引件数を設定する（データがない場合は0を設定）
      data[:count] = category_counts[category_name] || 0
      # カテゴリ名からカテゴリレIDを取得してデータに追加する（見つからない場合はnilを設定）
      data[:id] = Category.find_by(name: category_name)&.id
    end
    
    # グループ化されたハッシュの値部分（配列）を返却する
    grouped.values
  # 予期しないエラーが発生した場合の例外処理
  rescue StandardError => e
    # エラー情報をログに記録し、アプリケーションの継続性を保つ
    Rails.logger.error "Format category stats error: #{e.message}"
    # エラー時は空の配列を返却してフロントエンドでのエラーを回避する
    []
  end
# コントローラクラスの終了
end
