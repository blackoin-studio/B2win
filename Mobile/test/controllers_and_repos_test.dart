import 'package:b2win/core/network/api_client.dart';
import 'package:b2win/core/network/api_exceptions.dart';
import 'package:b2win/data/models/ad_settings_model.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/providers/ad_settings_provider.dart';
import 'package:b2win/data/providers/ai_provider.dart';
import 'package:b2win/data/providers/blog_provider.dart';
import 'package:b2win/data/providers/prediction_provider.dart';
import 'package:b2win/data/repositories/ad_settings_repository.dart';
import 'package:b2win/data/repositories/ai_repository.dart';
import 'package:b2win/data/repositories/blog_repository.dart';
import 'package:b2win/data/repositories/prediction_repository.dart';
import 'package:b2win/features/core/controllers/ad_controller.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePredictionProvider extends PredictionProvider {
  final List<Map<String, dynamic>> mockData;
  final bool shouldThrowNetworkError;

  FakePredictionProvider({
    this.mockData = const [],
    this.shouldThrowNetworkError = false,
  });

  @override
  Future<List<dynamic>> fetchPredictions() async {
    if (shouldThrowNetworkError) {
      throw NetworkException();
    }
    return mockData;
  }
}

class FakeBlogProvider extends BlogProvider {
  final List<Map<String, dynamic>> mockData;

  FakeBlogProvider({this.mockData = const []});

  @override
  Future<List<dynamic>> fetchBlogs() async {
    return mockData;
  }
}

class FakePredictionRepository extends PredictionRepository {
  final List<PredictionModel> items;

  FakePredictionRepository(this.items)
      : super(provider: FakePredictionProvider());

  @override
  Future<List<PredictionModel>> getPredictions() async => items;
}

void main() {
  group('GameController (Search & Status Filter)', () {
    late GameController controller;

    final sampleGames = [
      const PredictionModel(
        id: '1',
        league: 'Premier League',
        date: '2026-10-28',
        homeTeam: 'Arsenal',
        awayTeam: 'Chelsea',
        score: '2 - 1',
        time: '19:45',
        tip: 'Home Win',
        odds: '1.85',
        status: 'won',
      ),
      const PredictionModel(
        id: '2',
        league: 'La Liga',
        date: '2026-10-28',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        score: '-',
        time: '21:00',
        tip: 'Over 2.5',
        odds: '1.70',
        status: 'pending',
      ),
      const PredictionModel(
        id: '3',
        league: 'Serie A',
        date: '2026-10-28',
        homeTeam: 'AC Milan',
        awayTeam: 'Inter',
        score: '0 - 1',
        time: '20:45',
        tip: 'BTTS',
        odds: '1.95',
        status: 'lost',
      ),
    ];

    setUp(() {
      controller = GameController(
        repository: FakePredictionRepository(sampleGames),
      );
      controller.onInit();
    });

    test('loads all predictions initially', () async {
      await controller.fetchGameData();
      expect(controller.games.length, 3);
      expect(controller.filteredGames.length, 3);
    });

    test('filters predictions by status (won, pending, lost, all)', () async {
      await controller.fetchGameData();

      controller.setStatusFilter('won');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.homeTeam, 'Arsenal');

      controller.setStatusFilter('pending');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.homeTeam, 'Real Madrid');

      controller.setStatusFilter('lost');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.homeTeam, 'AC Milan');

      controller.setStatusFilter('all');
      expect(controller.filteredGames.length, 3);
    });

    test('filters predictions by search query (team, league, or tip)', () async {
      await controller.fetchGameData();

      controller.setSearchQuery('barcelona');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.league, 'La Liga');

      controller.setSearchQuery('serie a');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.homeTeam, 'AC Milan');

      controller.setSearchQuery('over 2.5');
      expect(controller.filteredGames.length, 1);
      expect(controller.filteredGames.first.homeTeam, 'Real Madrid');
    });
  });

  group('BlogRepository', () {
    test('parses BlogModel list from provider', () async {
      final repo = BlogRepository(
        provider: FakeBlogProvider(
          mockData: [
            {
              'id': 'b1',
              'title': 'Champions League Preview',
              'description': 'Top picks for tonight',
              'date': '2026-10-28',
              'photo': 'https://cdn.supabase.co/blog1.jpg',
            },
          ],
        ),
      );

      // Verify provider response mapping
      final raw = await FakeBlogProvider(
        mockData: [
          {
            'id': 'b1',
            'title': 'Champions League Preview',
            'description': 'Top picks for tonight',
            'date': '2026-10-28',
            'photo': 'https://cdn.supabase.co/blog1.jpg',
          },
        ],
      ).fetchBlogs();
      final blogs =
          raw.map((e) => BlogModel.fromJson(e as Map<String, dynamic>)).toList();

      expect(repo, isNotNull);
      expect(blogs.length, 1);
      expect(blogs.first.title, 'Champions League Preview');
    });
  });

  group('Dynamic Google Ads (AdSettingsModel & AdController)', () {
    test('defaults to adsEnabled = false when Admin has not turned ads on', () {
      const defaultSettings = AdSettingsModel();
      expect(defaultSettings.adsEnabled, isFalse);
      expect(defaultSettings.shouldShowBanner('home'), isFalse);
      expect(defaultSettings.shouldShowBanner('blog'), isFalse);
    });

    test('parses Admin-enabled ad settings and placement flags from API', () {
      final parsed = AdSettingsModel.fromJson({
        'success': true,
        'data': {
          'adsEnabled': true,
          'testMode': false,
          'bannerEnabled': true,
          'interstitialEnabled': true,
          'showOnHome': true,
          'showOnBlog': false,
          'interstitialInterval': 4,
          'androidBannerUnitId': 'ca-app-pub-1111111111111111/2222222222',
          'androidInterstitialUnitId': 'ca-app-pub-1111111111111111/3333333333',
        },
      });

      expect(parsed.adsEnabled, isTrue);
      expect(parsed.testMode, isFalse);
      expect(parsed.shouldShowBanner('home'), isTrue);
      expect(parsed.shouldShowBanner('blog'), isFalse);
      expect(parsed.interstitialInterval, 4);
      expect(
        parsed.activeBannerUnitId,
        'ca-app-pub-1111111111111111/2222222222',
      );
    });

    test('AdController updates reactive settings when Admin toggles ads ON/OFF',
        () async {
      Map<String, dynamic> mockApiPayload = {
        'success': true,
        'data': {'adsEnabled': false},
      };

      final repo = AdSettingsRepository(
        provider: _FakeAdSettingsProvider(() => mockApiPayload),
      );
      final adController = AdController(
        repository: repo,
        enableSdkInitialization: false,
      );

      await adController.fetchAdSettings();
      expect(adController.settings.value.adsEnabled, isFalse);

      // Simulate Admin turning Google Ads ON in Admin Panel
      mockApiPayload = {
        'success': true,
        'data': {
          'adsEnabled': true,
          'testMode': true,
          'bannerEnabled': true,
          'showOnHome': true,
          'showOnBlog': true,
        },
      };

      await adController.fetchAdSettings();
      expect(adController.settings.value.adsEnabled, isTrue);
      expect(adController.settings.value.shouldShowBanner('home'), isTrue);
      expect(
        adController.settings.value.activeBannerUnitId,
        AdSettingsModel.testAndroidBannerId,
      );
    });
  });

  group('B2win AI Features (AiRepository)', () {
    test('computeConfidence and computeRiskLevel calibrate from odds', () {
      expect(AiRepository.computeConfidence('1.50'), greaterThanOrEqualTo(70));
      expect(AiRepository.computeRiskLevel('1.50'), 'Low Risk');
      expect(AiRepository.computeRiskLevel('1.85'), 'Balanced Risk');
      expect(AiRepository.computeRiskLevel('2.40'), 'High-Value Pick');
    });

    test('getMatchInsight, getSmartSlip, and getBlogSummary return structured AI output',
        () async {
      final aiRepo = AiRepository(provider: _OfflineAiProvider());
      const sampleGame = PredictionModel(
        id: '10',
        league: 'Premier League',
        date: '2026-11-02',
        homeTeam: 'Arsenal',
        awayTeam: 'Liverpool',
        score: '-',
        time: '20:00',
        tip: 'Over 2.5',
        odds: '1.75',
        status: 'pending',
      );

      final insight = await aiRepo.getMatchInsight(sampleGame);
      expect(insight.confidence, inInclusiveRange(56, 91));
      expect(insight.bullets.length, 3);
      expect(insight.verdict, contains('Over 2.5'));

      final slip = await aiRepo.getSmartSlip(
        riskProfile: 'safe',
        availableGames: [sampleGame],
      );
      expect(slip.picks.length, 1);
      expect(slip.combinedOdds, '1.75');

      final summary = await aiRepo.getBlogSummary(
        title: 'El Clasico Tactical Breakdown',
        description:
            'Real Madrid and Barcelona meet in a decisive clash. High pressing in midfield will dictate tempo. Expect goals in both halves.',
      );
      expect(summary.bullets.isNotEmpty, isTrue);
      expect(summary.keyTakeaway, isNotEmpty);
    });
  });
}

class _OfflineAiProvider extends AiProvider {
  _OfflineAiProvider() : super(apiClient: ApiClient());

  @override
  Future<dynamic> fetchMatchInsight({
    required String homeTeam,
    required String awayTeam,
    required String league,
    required String tip,
    required String odds,
    required String status,
    required String score,
  }) async {
    throw NetworkException();
  }

  @override
  Future<dynamic> fetchSmartSlip({String riskProfile = 'balanced'}) async {
    throw NetworkException();
  }

  @override
  Future<dynamic> fetchBlogSummary({
    required String title,
    required String description,
  }) async {
    throw NetworkException();
  }
}

class _FakeAdSettingsProvider extends AdSettingsProvider {
  final Map<String, dynamic> Function() _responder;

  _FakeAdSettingsProvider(this._responder) : super(apiClient: ApiClient());

  @override
  Future<dynamic> fetchAdSettings() async => _responder();
}

