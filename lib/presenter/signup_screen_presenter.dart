
import 'package:user/data/rest_ds.dart';

abstract class SignupScreenContract {
  void onSignupSuccess(Map<String, Object> user);

  void onSignupError(String errorTxt);
}

class SignupScreenPresenter {
  SignupScreenContract _view;
  RestDatasource api = new RestDatasource();

  SignupScreenPresenter(this._view);

  doSignup(Map<String, dynamic> map) {
    api.signup(map).then((Map<String, Object> user) {
      _view.onSignupSuccess(user);
    }).catchError((Exception error) =>
    {
    _view.onSignupError(error.toString())
    });
  }

}
