

abstract class WalletServiceInterface{
  Future<dynamic> getDynamicWithDrawMethod();
  Future<dynamic> withdrawBalance(List <String?> typeKey, List<String> typeValue, int? id, String balance);
  Future<dynamic> getPaymentInfoList();
  Future<dynamic> closeWithdrawRequest(int? id, String balance);
  Future<dynamic> updateWithdrawRequest(List<String?> typeKey, List<String> typeValue, int? methodId, String balance, int requestId);
}