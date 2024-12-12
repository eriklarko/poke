import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/models/watering_plants/widgets/editable_plant_image.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/utils/date_formatter.dart';

class LogWaterActionWidget extends StatelessWidget {
  final WaterPlantAction action;
  final Function? onActionLogged;

  final persistence = GetIt.instance.get<Persistence>();

  // create controller used to set loading/success states of the button that
  // logs the action
  final _logActionController = PokeAsyncWidgetController();

  LogWaterActionWidget({super.key, required this.action, this.onActionLogged});

  @override
  Widget build(BuildContext context) {
    final lastEvent = action.getLastEvent();
    final plant = action.plant;
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      key: ValueKey(action.equalityKey),
      children: [
        EditablePlantImage(action: action),
        PokeText(plant.name),
        if (lastEvent != null)
          PokeText('Last watered on ${formatDate(lastEvent.$1)}'),
        Row(
          children: [
            PokeText('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeConstants.fixedSpacer(2),
        PokeAsyncWidget.simple(
          controller: _logActionController,
          idle: PokeButton.primary(
            text: 'Watered!',
            onPressed: () {
              _onActionButtonPressed(fertilizerCheckbox);
            },
          ),
          success: const Text('done!'),
          loading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          ),
          error: (error) {
            return Text(error.toString());
          },
        ),
      ],
    );
  }

  void _onActionButtonPressed(PokeCheckbox fertilizerCheckbox) {
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
      onActionLogged?.call();
    }).catchError((err) {
      _logActionController.setErrored(err);
    });
  }
}
