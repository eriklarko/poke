import 'package:get_it/get_it.dart';
import 'package:poke/persistence/persistence.dart';

void setPersistence(Persistence persistence) {
  setDependency<Persistence>(persistence);
}

void setDependency<T extends Object>(T t) {
  GetIt.instance.allowReassignment = true;
  GetIt.instance.registerSingleton<T>(t);
}
