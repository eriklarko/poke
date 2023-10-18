import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  // TODO: should probably be a Stream of some kind to allow a progress
  // indicator
  final Future loadingFuture;
  final Function? onLoadingDone;

  LoadingScreen({
    super.key,
    this.onLoadingDone,
    required this.loadingFuture,
  }) {
    loadingFuture.then((value) {
      print('Loading done!');
      onLoadingDone?.call();
      //
    }).onError((error, stackTrace) {
      print('Loading error! $error');
      if (error != null) {
        throw error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: PokeLoadingIndicator.large,
      ),
    );
  }
}
