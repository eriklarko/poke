import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/persistence.dart';

class LogActionWidget extends StatelessWidget {
  final WaterPlantAction action;
  final _logActionController = PokeAsyncWidgetController();

  final persistence = GetIt.instance.get<Persistence>();

  LogActionWidget(this.action, {super.key});

  @override
  Widget build(BuildContext context) {
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _waterButton(fertilizerCheckbox),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PokeFinePrint('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
      ],
    );
  }

  PokeAsyncWidget<dynamic> _waterButton(PokeCheckbox fertilizerCheckbox) {
    var pokeAsyncWidget = PokeAsyncWidget.simple(
      controller: _logActionController,
      idle: PokeButton.small(
        text: 'Watered!',
        onPressed: () {
          _onWaterButtonPressed(fertilizerCheckbox);
        },
      ),
      success: const Text('done!'),
      loading: const SizedBox(
        width: 20,
        height: 20,
        child: PokeLoadingIndicator.small(),
      ),
      error: (error) {
        return Text(error.toString());
      },
    );
    return pokeAsyncWidget;
  }

  void _onWaterButtonPressed(PokeCheckbox fertilizerCheckbox) {
    _logActionController.setLoading();

    PokeLogger.instance().debug(
      'Pressed water plant button',
      data: {'fertCheckboxChecked': fertilizerCheckbox.isChecked},
    );

    persistence
        .logAction(action, clock.now(),
            eventData: WaterEventData(
              addedFertilizer: fertilizerCheckbox.isChecked,
            ))
        .then((_) {
      _logActionController.setSuccessful();
    }).catchError((err) {
      _logActionController.setErrored(err);
    });
  }
}
