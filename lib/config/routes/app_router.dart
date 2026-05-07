import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokoku/domain/entities/user_entity.dart';
import 'package:tokoku/presentation/blocs/cart/cart_state.dart';

import '../../domain/repositories/product_repository.dart';
import '../../injection_container.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/product/product_form_screen.dart';
import '../../presentation/screens/transaction/transaction_screen.dart';
import '../../presentation/screens/transaction/cart_screen.dart';
import '../../presentation/screens/transaction/invoice_screen.dart';
import '../../presentation/screens/home/user_form_screen.dart';
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
  static const String userAdd = '/user/add';
  static const String userEdit = '/user/edit/:id';
  static const String transaction = '/transaction';
  static const String cart = '/transaction/cart';
  static const String invoice = '/transaction/invoice';

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

        // Hanya ke Splash saat pertama kali aplikasi dibuka (Initial)
        if (authState is AuthInitial) {
          return isOnSplash ? null : splash;
        }

        // Jika sedang loading (login/logout), jangan pindah halaman dulu (biar ditangani LoadingOverlay)
        if (authState is AuthLoading) {
          return null;
        }

        // Jika sedang di Splash dan status sudah jelas, arahkan ke home atau login
        if (isOnSplash) {
          if (authState is AuthAuthenticated) return home;
          if (authState is AuthUnauthenticated) return login;
          return null;
        }

        // Pendaftaran berhasil — arahkan ke login
        if (authState is AuthRegistrationSuccess) {
          return isOnLogin ? null : login;
        }

        // Belum login atau terjadi error — arahkan ke login (kecuali jika sedang di register)
        if (authState is AuthUnauthenticated || authState is AuthError) {
          if (isOnRegister) return null;
          return isOnLogin ? null : login;
        }

        // Sudah login — arahkan ke home
        if (authState is AuthAuthenticated) {
          final isAdmin = authState.user.role == 'admin';
          final isRestrictedPath =
              state.matchedLocation == productAdd ||
              state.matchedLocation.startsWith('/product/edit') ||
              state.matchedLocation == userAdd ||
              state.matchedLocation.startsWith('/user/edit');

          // Jika bukan admin mencoba akses halaman admin, lempar balik ke home
          if (!isAdmin && isRestrictedPath) {
            return home;
          }

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
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            int initialIndex = 0;
            if (tab == 'transaction') initialIndex = 2;
            return HomeScreen(initialIndex: initialIndex);
          },
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
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }
                return ProductFormScreen(product: snapshot.data!);
              },
            );
          },
        ),
        GoRoute(
          path: userAdd,
          name: 'userAdd',
          builder: (context, state) => const UserFormScreen(),
        ),
        GoRoute(
          path: userEdit,
          name: 'userEdit',
          builder: (context, state) {
            final user = state.extra as UserEntity;
            return UserFormScreen(user: user);
          },
        ),
        GoRoute(
          path: transaction,
          name: 'transaction',
          builder: (context, state) => const TransactionScreen(),
        ),
        GoRoute(
          path: cart,
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: invoice,
          name: 'invoice',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final cartState = extra['cartState'] as CartState;
            final cash = extra['cash'] as double;
            final change = extra['change'] as double;
            final invoiceNo = extra['invoiceNo'] as String;
            final paymentMethod = extra['paymentMethod'] as String? ?? 'Tunai / Cash';

            return InvoiceScreen(
              cartState: cartState,
              cash: cash,
              change: change,
              invoiceNo: invoiceNo,
              paymentMethod: paymentMethod,
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
