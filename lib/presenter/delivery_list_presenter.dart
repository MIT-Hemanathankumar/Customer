
import 'package:user/data/rest_ds.dart';

abstract class DeliveryListCotract {
  void onDeliveryListSuccess(Map<String, Object> user);

  void onDeliveryListError(String errorTxt);
}

class DeliveryListPresenter {
  DeliveryListCotract _view;
  RestDatasource api = new RestDatasource();

  DeliveryListPresenter(this._view);

  doDeliveryList(String userId, String password) {
    api.deliverylistGetMethod(userId, password).then((Map<String, Object> user) {
      _view.onDeliveryListSuccess(user);
    }).catchError((Exception error) =>
    {
    _view.onDeliveryListError(error.toString())
    });
  }

}
