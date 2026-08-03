import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/account.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';

class AccountService extends GetxService {
  final IAccountResponsitory accountResponsitory;
  final Rx<Account?> _myAccount = Rx(null);
  Stream<Account?> get accountStream => _myAccount.stream;
  Account? get account => _myAccount.value;

  AccountService({required this.accountResponsitory});

  void setAccount(Account account) {
    _myAccount.value = account;
  }

  Future<void> onGetUserProfile() async {
    try {
      final result = await accountResponsitory.getProfile();
      _myAccount.value = result;
    } catch (e) {
      print(e);
    }
  }
}
