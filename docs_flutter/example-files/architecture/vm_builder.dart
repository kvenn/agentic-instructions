import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'appearance_listener_widget.dart';
import 'view_model.dart';

typedef UpdateCallback<ViewModelT> = ViewModelT Function(
  BuildContext,
  ViewModelT,
);

/// A simple wrapper for when you provide and then immediately consume
/// a [ChangeNotifier]. If you need something more custom, (like
/// [ChangeNotifierProxyProvider]), just use it directly and wrap with
/// [AppearanceListenerWidget].
class VmBuilder<ViewModelT extends ViewModel> extends StatelessWidget {
  final ViewModelT Function() create;
  final Widget Function(BuildContext, ViewModelT, Widget?) builder;
  final Widget? child;
  final UpdateCallback<ViewModelT>? update;

  const VmBuilder(
    this.create, {
    required this.builder,
    this.update,
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final finalUpdate = update;
    return ChangeNotifierProxyProvider0<ViewModelT>(
      create: (_) => create(),
      update: (_, viewModel) {
        if (viewModel == null) {
          return create();
        }
        if (finalUpdate != null) {
          return finalUpdate(context, viewModel);
        }

        return viewModel;
      },
      child: Consumer<ViewModelT>(
        builder: (_, viewModel, child) {
          return AppearanceListenerWidget<ViewModelT>(
            viewModel: viewModel,
            builder: builder,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

// If we realized using updates everywhere are more expensive, we can create
// specific models like the following:
// class VmUpdateBuilder<ViewModelT extends ViewModel> extends StatelessWidget {
//   final ViewModelT Function() create;
//   final Widget Function(BuildContext, ViewModelT, Widget?) builder;
//   final Widget? child;
//   final UpdateCallback<ViewModelT> update;
//
//   const VmUpdateBuilder(
//       this.create, {
//         required this.builder,
//         required this.update,
//         super.key,
//         this.child,
//       });
//
//   @override
//   Widget build(BuildContext context) {
//     final finalUpdate = update;
//     return ChangeNotifierProxyProvider0<ViewModelT>(
//       create: (_) => create(),
//       update: (_, viewModel) {
//         if (viewModel == null) {
//           return create();
//         }
//         if (finalUpdate != null) {
//           return finalUpdate(context, viewModel);
//         }
//
//         return viewModel;
//       },
//       child: Consumer<ViewModelT>(
//         builder: (_, viewModel, child) {
//           return AppearanceListenerWidget<ViewModelT>(
//             viewModel: viewModel,
//             builder: builder,
//             child: child,
//           );
//         },
//         child: child,
//       ),
//     );
//   }
// }
