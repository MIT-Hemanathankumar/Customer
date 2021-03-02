
import 'package:user/data/rest_ds.dart';

abstract class PharmacyListCotract {
  void onPharmacyListSuccess(Map<String, Object> user);

  void onPharmacyListError(String errorTxt);
}

class PharmacyListPresenter {
  PharmacyListCotract _view;
  RestDatasource api = new RestDatasource();

  PharmacyListPresenter(this._view);

  doPharmacyList(String pincode) {
    api.pharmacylistGetMethod(pincode).then((Map<String, Object> user) {
      _view.onPharmacyListSuccess(user);
    }).catchError((Exception error) =>
    {
    _view.onPharmacyListError(error.toString())
    });
  }

}
