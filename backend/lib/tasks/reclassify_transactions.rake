require 'nkf'

namespace :db do
  desc "Reclassify existing transactions based on current keyword rules"
  task reclassify_transactions: :environment do
    puts "既存トランザクションの再分類を開始します..."

    # 「その他」カテゴリのトランザクションを取得
    other_category = Category.find_by(name: 'その他')

    if other_category.nil?
      puts "「その他」カテゴリが見つかりません"
      exit 1
    end

    transactions = Transaction.where(category_id: other_category.id)
    total_count = transactions.count

    puts "対象トランザクション: #{total_count}件"

    reclassified_count = 0
    unchanged_count = 0

    transactions.find_each.with_index do |transaction, index|
      # 店舗名を正規化（半角カタカナ→全角カタカナ）
      store_name = transaction.store_name
      next if store_name.blank?

      # NKFで半角カタカナを全角カタカナに変換
      normalized_store_name = NKF.nkf('-w -Z1', store_name)

      # CategoryClassifierServiceを使って再分類
      classifier = CategoryClassifierService.new
      new_category = classifier.classify(normalized_store_name)

      if new_category && new_category.id != other_category.id
        # カテゴリを更新
        transaction.update_columns(
          category_id: new_category.id,
          auto_classified: true
        )
        reclassified_count += 1
        puts "[#{index + 1}/#{total_count}] 再分類: #{store_name} → #{new_category.name}"
      else
        unchanged_count += 1
      end

      # 進捗表示（10件ごと）
      if (index + 1) % 10 == 0
        puts "進捗: #{index + 1}/#{total_count} (再分類: #{reclassified_count}件, 未変更: #{unchanged_count}件)"
      end
    end

    puts "\n再分類完了:"
    puts "  再分類済み: #{reclassified_count}件"
    puts "  未変更（その他のまま）: #{unchanged_count}件"
    puts "  総処理件数: #{total_count}件"

    # 最終確認
    remaining_other = Transaction.where(category_id: other_category.id).count
    puts "\n残りの「その他」カテゴリ: #{remaining_other}件"
  end
end
