module Mojaik::Heco
  class Wallet < ::Mojaik::WalletAbstract
    include Params

    def prepare_deposit_collection!(deposit_transaction, spread_transactions, deposit_currency)
      super
    end
  end
end
