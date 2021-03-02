
import 'package:user/data/rest_ds.dart';

abstract class CountryListCotract {
  void onCountryListSuccess(Map<String, Object> user);

  void onCountryListError(String errorTxt);
}

class CountryListPresenter {
  CountryListCotract _view;
  RestDatasource api = new RestDatasource();

  CountryListPresenter(this._view);

  doCountryList() {
    api.countrylistGetMethod().then((Map<String, Object> user) {
      _view.onCountryListSuccess(user);
    }).catchError((Exception error) =>
    {
    _view.onCountryListError(error.toString())
    });
  }

}
