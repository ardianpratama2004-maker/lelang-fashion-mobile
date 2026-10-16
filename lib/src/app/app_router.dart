import 'package:go_router/go_router.dart';

import '../core/notifications/daily_reminder_service.dart';
import '../core/session/auth_controller.dart';
import '../data/api/api_client.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/auctions/data/api_auction_repository.dart';
import '../features/auctions/presentation/auction_detail_screen.dart';
import '../features/auctions/presentation/favorite_auction_screen.dart';
import '../features/auctions/presentation/auction_list_screen.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/bids/data/api_bid_repository.dart';
import '../features/chat/data/api_chat_repository.dart';
import '../features/chat/presentation/chat_detail_screen.dart';
import '../features/chat/presentation/chat_thread_list_screen.dart';
import '../features/profile/data/api_profile_repository.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settlements/data/api_settlement_repository.dart';
import '../features/shell/presentation/home_shell.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/wins/data/api_win_repository.dart';

class AppRouter {
  AppRouter({
    required ApiClient api,
    required AuthController auth,
    required DailyReminderService reminders,
  })
    : router = GoRouter(
        initialLocation: '/splash',
        refreshListenable: auth,
        redirect: (context, state) {
          final location = state.uri.path;

          if (auth.loading) {
            return location == '/splash' ? null : '/splash';
          }

          if (!auth.isAuthenticated) {
            return location == '/masuk' || location == '/daftar'
                ? null
                : '/masuk';
          }

          if (location == '/auth' ||
              location == '/masuk' ||
              location == '/daftar' ||
              location == '/splash') {
            return '/lelang';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(path: '/auth', redirect: (context, state) => '/masuk'),
          GoRoute(
            path: '/masuk',
            builder: (context, state) => AuthScreen(
              repository: ApiAuthRepository(api),
              auth: auth,
              register: false,
            ),
          ),
          GoRoute(
            path: '/daftar',
            builder: (context, state) => AuthScreen(
              repository: ApiAuthRepository(api),
              auth: auth,
              register: true,
            ),
          ),
          GoRoute(
            path: '/lelang/:id',
            builder: (context, state) => AuctionDetailScreen(
              repository: ApiAuctionRepository(api),
              chatRepository: ApiChatRepository(api),
              productId: int.parse(state.pathParameters['id']!),
              currentUserId: auth.user?.id,
            ),
          ),
          GoRoute(
            path: '/favorit',
            builder: (context, state) =>
                FavoriteAuctionScreen(repository: ApiAuctionRepository(api)),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (context, state) => ChatDetailScreen(
              repository: ApiChatRepository(api),
              threadId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/bid-saya',
            redirect: (context, state) => '/aktivitas?tab=bid',
          ),
          GoRoute(
            path: '/kemenangan',
            redirect: (context, state) => '/aktivitas?tab=menang',
          ),
          GoRoute(
            path: '/pelunasan',
            redirect: (context, state) => '/aktivitas?tab=bayar',
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => HomeShell(
              navigationShell: navigationShell,
              auth: auth,
              reminders: reminders,
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/lelang',
                    builder: (context, state) => AuctionListScreen(
                      repository: ApiAuctionRepository(api),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/aktivitas',
                    builder: (context, state) => ActivityScreen(
                      bidRepository: ApiBidRepository(api),
                      winRepository: ApiWinRepository(api),
                      settlementRepository: ApiSettlementRepository(api),
                      initialTab: state.uri.queryParameters['tab'] ?? 'bid',
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/chat',
                    builder: (context, state) => ChatThreadListScreen(
                      repository: ApiChatRepository(api),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profil',
                    builder: (context, state) => ProfileScreen(
                      repository: ApiProfileRepository(api),
                      auth: auth,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  final GoRouter router;
}
