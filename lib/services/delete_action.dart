import 'package:flutter/widgets.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/utils/nav_service.dart';

Future<void> deleteAction(
  BuildContext context,
  Action action,
) async {
  final persistence = GetIt.instance.get<Persistence>();
  Function? onceDeleted; // helper to close the modal

  final modal = PokeModal(
    child: Column(
      children: [
        PokeText("DANGEROUS"),
        PokeAsyncButton.primaryDangerous(
          text: "DELETE NOW",
          onPressed: () async {
            await persistence.deleteAction(action.equalityKey);

            if (onceDeleted == null) {
              PokeLogger.instance().warn(
                "unable to dismiss delete action modal because `onceDeleted` is null",
                data: {
                  "actionId": action.equalityKey,
                },
              );
            } else {
              onceDeleted();
            }

            // Take the user back home
            NavService.reset(HomeScreen());
          },
        ),
      ],
    ),
  );
  onceDeleted = modal.dismiss;

  modal.show(context);
}
