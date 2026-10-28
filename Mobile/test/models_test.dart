import 'package:flutter_test/flutter_test.dart';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/models/blog_model.dart';
import 'package:b2win/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should parse flat JSON correctly', () {
      final json = {
        '_id': '123',
        'username': 'testuser',
        'email': 'test@example.com',
        'token': 'sample_token',
      };
      final user = UserModel.fromJson(json);

      expect(user.id, '123');
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.token, 'sample_token');
      expect(user.isAdmin, false);
    });

    test('should parse nested Supabase Auth login JSON correctly', () {
      final json = {
        'token': 'sb_access_token',
        'refreshToken': 'sb_refresh_token',
        'user': {
          'id': 'uuid-456',
          'username': 'adminuser',
          'email': 'admin@b2win.com',
          'isAdmin': true,
        },
      };
      final user = UserModel.fromJson(json);

      expect(user.id, 'uuid-456');
      expect(user.username, 'adminuser');
      expect(user.email, 'admin@b2win.com');
      expect(user.token, 'sb_access_token');
      expect(user.refreshToken, 'sb_refresh_token');
      expect(user.isAdmin, true);
    });

    test('should serialize to JSON correctly', () {
      const user = UserModel(
        id: '123',
        username: 'testuser',
        email: 'test@example.com',
        token: 'sample_token',
        refreshToken: 'refresh_123',
        isAdmin: true,
      );
      final json = user.toJson();

      expect(json['_id'], '123');
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['token'], 'sample_token');
      expect(json['refreshToken'], 'refresh_123');
      expect(json['isAdmin'], true);
    });
  });

  group('resolveMediaUrl', () {
    test('returns empty string for null, empty, or placeholder filenames', () {
      expect(resolveMediaUrl(null), '');
      expect(resolveMediaUrl(''), '');
      expect(resolveMediaUrl('no-league-photo.jpg'), '');
      expect(resolveMediaUrl('no-home-photo.jpg'), '');
    });

    test('resolves relative filenames and preserves full URLs', () {
      expect(resolveMediaUrl('team1.png'), '$imageUrl/team1.png');
      expect(
        resolveMediaUrl('https://cdn.supabase.co/logo.png'),
        'https://cdn.supabase.co/logo.png',
      );
    });
  });

  group('PredictionModel', () {
    test('should parse JSON correctly and provide fallback defaults', () {
      final json = {
        '_id': 'p1',
        'league': 'Premier League',
        'date': '2026-10-24T12:00:00Z',
        'awayTeam': 'Arsenal',
        'homeTeam': 'Chelsea',
        'score': '2-1',
        'time': '15:00',
        'tip': 'Over 2.5',
        'odds': '1.85',
        'status': 'WON',
      };
      final prediction = PredictionModel.fromJson(json);

      expect(prediction.id, 'p1');
      expect(prediction.league, 'Premier League');
      expect(prediction.awayTeam, 'Arsenal');
      expect(prediction.homeTeam, 'Chelsea');
      expect(prediction.status, 'won');
      expect(prediction.odds, '1.85');
    });

    test('roundtrip serialization should preserve values', () {
      const original = PredictionModel(
        id: 'p2',
        league: 'La Liga',
        date: '2026-10-25',
        awayTeam: 'Real Madrid',
        homeTeam: 'Barcelona',
        score: '0-0',
        time: '20:00',
        tip: 'Both Teams To Score',
        odds: '1.90',
        status: 'pending',
      );
      final json = original.toJson();
      final reconstructed = PredictionModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.league, original.league);
      expect(reconstructed.awayTeam, original.awayTeam);
      expect(reconstructed.homeTeam, original.homeTeam);
      expect(reconstructed.tip, original.tip);
    });
  });

  group('BlogModel', () {
    test('should parse JSON correctly', () {
      final json = {
        '_id': 'b1',
        'title': 'Match Analysis',
        'description': 'Deep dive into weekend matches',
        'date': '2026-10-24',
        'photo': 'blog1.jpg',
      };
      final blog = BlogModel.fromJson(json);

      expect(blog.id, 'b1');
      expect(blog.title, 'Match Analysis');
      expect(blog.photo, 'blog1.jpg');
    });

    test('roundtrip serialization should preserve values', () {
      const original = BlogModel(
        id: 'b2',
        title: 'Tactics Breakdown',
        description: 'Formation analysis',
        date: '2026-10-25',
        photo: 'tactics.jpg',
      );
      final json = original.toJson();
      final reconstructed = BlogModel.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.title, original.title);
      expect(reconstructed.description, original.description);
      expect(reconstructed.photo, original.photo);
    });
  });
}
