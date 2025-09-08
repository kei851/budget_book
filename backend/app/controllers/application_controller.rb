# API専用のベースコントローラクラス
# ActionController::APIを継承し、JSON APIに特化した軽量な機能のみ提供
# 通常のRailsアプリのようなビュー、セッション、Cookie機能は除外されている
class ApplicationController < ActionController::API
end
