import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/product_repository.dart';
import '../../injection_container.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/product/product_form_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

/// Konfigurasi routing menggunakan GoRouter.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String productAdd = '/product/add';
  static const String productEdit = '/product/edit/:id';

  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: splash,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isOnSplash = state.matchedLocation == splash;
        final isOnLogin = state.matchedLocation == login;
        final isOnRegister = state.matchedLocation == register;

        // Masih loading — jika di halaman auth (login/register), tetap di sana
        if (authState is AuthLoading || authState is AuthInitial) {
          if (isOnLogin || isOnRegister) return null;
          return isOnSplash ? null : splash;
        }

        // Jika sedang di Splash, biarkan SplashScreen yang mengatur navigasi awal
        if (isOnSplash) return null;

        // Pendaftaran berhasil — arahkan ke login
        if (authState is AuthRegistrationSuccess) {
          return isOnLogin ? null : login;
        }

        // Belum login — arahkan ke login (kecuali jika sedang di register)
        if (authState is AuthUnauthenticated) {
          if (isOnRegister) return null;
          return isOnLogin ? null : login;
        }

        // Sudah login — arahkan ke home
        if (authState is AuthAuthenticated) {
          return (isOnLogin || isOnRegister) ? home : null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: productAdd,
          name: 'productAdd',
          builder: (context, state) => const ProductFormScreen(),
        ),
        GoRoute(
          path: productEdit,
          name: 'productEdit',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return FutureBuilder(
              future: sl<ProductRepository>().getProductById(productId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  );
                }
                return ProductFormScreen(product: snapshot.data!);
              },
            );
          },
        ),
      ],
    );
  }
}

/// Adapter agar GoRouter bisa listen ke BLoC stream sebagai Listenable.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
