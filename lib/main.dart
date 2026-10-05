import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'shop_app.dart';
import 'shop_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = ShopState();
  await state.initialize();
  runApp(ChangeNotifierProvider.value(value: state, child: const ShopApp()));
}
