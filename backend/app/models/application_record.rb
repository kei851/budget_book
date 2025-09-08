# ApplicationRecordクラスはActiveRecord::Baseを継承している。つまり、ApplicationRecordはデータベースと連携可能
class ApplicationRecord < ActiveRecord::Base
  # ApplicationRecordクラスはprimary_abstract_classメソッドを呼び出す。
  # この表現は一般的で、このメソッドを呼び出すことで、これが呼び出されたクラスは抽象クラスであることがわかる！
  primary_abstract_class
end