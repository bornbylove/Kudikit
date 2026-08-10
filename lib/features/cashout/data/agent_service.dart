import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kudipay/features/agent/domain/entities/agent_model.dart';

import 'geo_service.dart';

class AgentService {
  static final AgentService _instance = AgentService._internal();
  factory AgentService() => _instance;
  AgentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoService _geoService = GeoService();

  Future<List<AgentModel>> getNearbyAgents({
    required Position userPosition,
    double radiusKm = 5.0,
  }) async {
    try {
      final bounds = _calculateBounds(
        userPosition.latitude,
        userPosition.longitude,
        radiusKm,
      );

      final query = await _firestore
          .collection('agents')
          .where('isAvailable', isEqualTo: true)
          .where(
            'location',
            isGreaterThan: GeoPoint(bounds['minLat']!, bounds['minLng']!),
          )
          .where(
            'location',
            isLessThan: GeoPoint(bounds['maxLat']!, bounds['maxLng']!),
          )
          .get();

      List<AgentModel> agents =
          query.docs.map((doc) => AgentModel.fromFirestore(doc)).toList();

      for (var agent in agents) {
        agent.distanceKm = _geoService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          agent.location.latitude,
          agent.location.longitude,
        );
      }

      agents = agents.where((a) => a.distanceKm! <= radiusKm).toList();

      agents.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));

      return agents;
    } catch (e) {
      return _getMockNearbyAgents(userPosition);
    }
  }

  List<AgentModel> _getMockNearbyAgents(Position userPosition) {
    final agents = AgentModel.mockAgents();
    for (var agent in agents) {
      agent.distanceKm = _geoService.calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        agent.location.latitude,
        agent.location.longitude,
      );
    }
    agents.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return agents;
  }

  Future<AgentModel?> getAgentById(String agentId) async {
    try {
      final doc = await _firestore.collection('agents').doc(agentId).get();
      if (doc.exists) return AgentModel.fromFirestore(doc);
    } catch (e) {
      return AgentModel.mockAgents().firstWhere(
        (a) => a.id == agentId,
        orElse: () => AgentModel.mockAgents().first,
      );
    }
    return null;
  }

  Future<List<AgentModel>> searchAgentsByAddress({
    required String query,
    required Position userPosition,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('agents')
          .where('isAvailable', isEqualTo: true)
          .get();

      final queryLower = query.toLowerCase();
      List<AgentModel> agents = snapshot.docs
          .map((doc) => AgentModel.fromFirestore(doc))
          .where((agent) =>
              agent.address.toLowerCase().contains(queryLower) ||
              agent.shopName.toLowerCase().contains(queryLower))
          .toList();

      for (var agent in agents) {
        agent.distanceKm = _geoService.calculateDistance(
          userPosition.latitude,
          userPosition.longitude,
          agent.location.latitude,
          agent.location.longitude,
        );
      }

      agents.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      return agents;
    } catch (e) {
      final all = AgentModel.mockAgents();
      final queryLower = query.toLowerCase();
      return all
          .where((a) =>
              a.address.toLowerCase().contains(queryLower) ||
              a.shopName.toLowerCase().contains(queryLower))
          .toList();
    }
  }

  Map<String, double> _calculateBounds(
    double lat,
    double lng,
    double radiusKm,
  ) {
    const double latDegreePerKm = 1 / 110.574;
    final double lngDegreePerKm = 1 / (111.320 * _cos(lat * 3.14159 / 180));

    final double latDelta = radiusKm * latDegreePerKm;
    final double lngDelta = radiusKm * lngDegreePerKm;

    return {
      'minLat': lat - latDelta,
      'maxLat': lat + latDelta,
      'minLng': lng - lngDelta,
      'maxLng': lng + lngDelta,
    };
  }

  double _cos(double angle) {
    return 1 - (angle * angle) / 2 + (angle * angle * angle * angle) / 24;
  }
}
