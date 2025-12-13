import 'package:flutter/material.dart';
import 'package:hecate/features/bindings/domain/bindings_state.dart';
import 'package:yx_state/yx_state.dart';
import 'package:yx_state_flutter/yx_state_flutter.dart';

class BindingStateBanner extends StatelessWidget {
  final StateReadable<BindingsState> stateReadable;

  BindingStateBanner({
    required this.stateReadable,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StateBuilder<BindingsState>(
      stateReadable: stateReadable,
      builder: (context, state, _) {
        final (Color color, String label, IconData icon) = switch (state) {
          // closed states
          BindingsState$Opening() => (
            Colors.amber.shade400,
            'Bindings: opening',
            Icons.access_time,
          ),
          BindingsState$OpeningError() => (
            Colors.redAccent.shade200,
            'Bindings: error',
            Icons.highlight_off,
          ),
          BindingsState$OpeningFailed() => (
            Colors.redAccent.shade200,
            'Bindings: open failed',
            Icons.highlight_off,
          ),
          BindingsState$Closed() => (
            Colors.grey.shade700,
            'Bindings: closed',
            Icons.lock,
          ),
          // opened states
          BindingsState$CallError() => (
            Colors.deepOrange.shade200,
            'Bindings: call error',
            Icons.explicit,
          ),
          BindingsState$CallFailed() => (
            Colors.deepOrange.shade200,
            'Bindings: call failed',
            Icons.explicit,
          ),
          BindingsState$InconsistentState(:final type) => switch (type) {
            BindingsInconsistentType.missingKeys => (
              Colors.orange.shade300,
              'Bindings: keys missing',
              Icons.vpn_key,
            ),
            BindingsInconsistentType.pinRequired => (
              Colors.orange.shade300,
              'Bindings: PIN required',
              Icons.pin,
            ),
          },
          BindingsState$Opened() => (
            Colors.greenAccent.shade400,
            'Bindings: connected',
            Icons.usb_rounded,
          ),
        };

        return DecoratedBox(
          decoration: ShapeDecoration(
            color: color.withValues(alpha: 0.8),
            shape: StadiumBorder(),
            shadows: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.black87,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
