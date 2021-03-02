
import 'package:user/data/rest_ds.dart';

abstract class LoginScreenContract {
  void onLoginSuccess(Map<String, Object> user);

  void onLoginError(String errorTxt);
}

class LoginScreenPresenter {
  LoginScreenContract _view;
  RestDatasource api = new RestDatasource();

  LoginScreenPresenter(this._view);

  doLogin(String username, String password) {
    api.loginGetMethod(username, password).then((Map<String, Object> user) {
      _view.onLoginSuccess(user);
    }).catchError((Exception error) =>
    {
    _view.onLoginError(error.toString())
    });
  }

}
