import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Resolve and switch between bloc context:
/// 'listen' = true: Reactive rebuild or 'listen' = false: Build Once
// B → Bloc type
// R → Result type
/// USAGE:
// final total = withBloc<CompanyStoresBloc, int>(
//       context,
//       listen: true,
//       builder: (bloc) {
//         final state = bloc.state;
//         if (state is! SetupsLoaded<CompanyStore>) return 0;
//         return state.data.length;
//       },
//     );
R withBloc<B, R>(
  BuildContext context, {
  required bool listen,
  required R Function(B bloc) builder,
}) {
  final bloc = listen ? context.watch<B>() : context.read<B>();

  return builder(bloc);
}

/* T useBloc<T>(
      BuildContext context, {
        required bool listen,
        required T Function(CompanyStoresBloc bloc) builder,
      }) {
    final bloc = listen
        ? context.watch<CompanyStoresBloc>()
        : context.read<CompanyStoresBloc>();

    return builder(bloc);
  }*/
