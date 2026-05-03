import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tokoku/presentation/blocs/cart/cart_bloc.dart';
import 'package:tokoku/presentation/blocs/user/user_bloc.dart';

import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_state.dart';
import 'presentation/blocs/history/history_bloc.dart';

/// Root widget aplikasi Tokoku.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested())),
        BlocProvider(create: (_) => sl<ProductBloc>()),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()..add(DashboardFetchRequested())),
        BlocProvider(create: (_) => sl<HistoryBloc>()),
        BlocProvider.value(value: sl<UserBloc>()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return MaterialApp.router(
      title: 'Tokoku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router(authBloc),
    );
  }
}
