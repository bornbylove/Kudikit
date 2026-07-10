import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kudipay/model/agent/agent_model.dart';
import 'package:kudipay/presentation/cashout/agent_detail_screen.dart';
import 'package:kudipay/shared/widgets/agent_list_tile.dart';
import 'package:kudipay/provider/cashout/cashout_provider.dart';

class CashOutMapScreen extends ConsumerStatefulWidget {
  const CashOutMapScreen({super.key});

  @override
  ConsumerState<CashOutMapScreen> createState() => _CashOutMapScreenState();
}

class _CashOutMapScreenState extends ConsumerState<CashOutMapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _showAgentList = true;
  Set<Marker> _markers = {};
  bool _hasAnimatedToUser = false; // guard: only animate once on first fix

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashOutProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // FIX #5: Build markers here — called from ref.listen, NOT inside build().
  // This prevents setState being triggered during a build cycle.
  void _rebuildMarkers(List<AgentModel> agents) {
    if (!mounted) return;
    setState(() {
      _markers = agents.map((agent) {
        return Marker(
          markerId: MarkerId(agent.id),
          position: LatLng(agent.location.latitude, agent.location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            agent.isAvailable
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: agent.shopName,
            snippet:
                '${agent.distanceKm?.toStringAsFixed(1)}km · ${agent.commissionPercent}% fee',
          ),
          onTap: () => _selectAgent(agent),
        );
      }).toSet();
    });
  }

  void _animateToUserLocation(CashOutState state) {
    if (state.userPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(state.userPosition!.latitude, state.userPosition!.longitude),
          14,
        ),
      );
    }
  }

  void _selectAgent(AgentModel agent) {
    ref.read(cashOutProvider.notifier).selectAgent(agent);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgentDetailsScreen(agent: agent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashOutProvider);

    // FIX #5: Use ref.listen for side-effects (marker rebuild + camera animation).
    // This runs AFTER build completes — never during — eliminating setState-in-build.
    ref.listen<CashOutState>(cashOutProvider, (previous, next) {
      // Rebuild markers when agent list changes
      if (previous?.nearbyAgents != next.nearbyAgents) {
        _rebuildMarkers(next.nearbyAgents);
      }
      // Animate camera once when user position first arrives
      if (previous?.userPosition == null &&
          next.userPosition != null &&
          !_hasAnimatedToUser) {
        _hasAnimatedToUser = true;
        _animateToUserLocation(next);
      }
    });

    final initialCameraPosition = state.userPosition != null
        ? CameraPosition(
            target: LatLng(
                state.userPosition!.latitude, state.userPosition!.longitude),
            zoom: 14,
          )
        : const CameraPosition(
            target: LatLng(6.4281, 3.4219), // Lagos fallback
            zoom: 12,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cash Out',
          style: TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(cashOutProvider.notifier).searchAgents(value),
                decoration: const InputDecoration(
                  hintText: 'Search by address or landmark',
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.black38, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Map
          Expanded(
            flex: _showAgentList ? 2 : 5,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Animate if location already available when map creates
                    if (state.userPosition != null && !_hasAnimatedToUser) {
                      _hasAnimatedToUser = true;
                      _animateToUserLocation(state);
                    }
                  },
                ),

                // Location loading overlay
                if (state.isLoadingLocation)
                  Container(
                    color: Colors.white.withValues(alpha: 0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2BA89A)),
                          SizedBox(height: 12),
                          Text('Getting your location...',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                // Error banner
                if (state.errorMessage != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                ref.read(cashOutProvider.notifier).clearError(),
                            child: Icon(Icons.close,
                                color: Colors.red.shade400, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // My-location FAB
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: () => _animateToUserLocation(state),
                    backgroundColor: Colors.white,
                    elevation: 4,
                    child:
                        const Icon(Icons.my_location, color: Color(0xFF2BA89A)),
                  ),
                ),
              ],
            ),
          ),

          // Agent list panel
          if (_showAgentList)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Panel header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          if (state.isLoadingAgents)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF2BA89A), strokeWidth: 2),
                            )
                          else
                            Text(
                              '${state.nearbyAgents.length} available agent${state.nearbyAgents.length != 1 ? "s" : ""}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87),
                            ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _showAgentList = false),
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // Agent list
                    Expanded(
                      child: state.isLoadingAgents
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF2BA89A)))
                          : state.nearbyAgents.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No agents found nearby.\nTry searching a different area.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black45, fontSize: 13),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: state.nearbyAgents.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, indent: 70),
                                  itemBuilder: (context, index) {
                                    final agent = state.nearbyAgents[index];
                                    return AgentListTile(
                                      agent: agent,
                                      onTap: () => _selectAgent(agent),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),

          // "Show agents" chip when list is hidden
          if (!_showAgentList)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => setState(() => _showAgentList = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2BA89A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Show ${state.nearbyAgents.length} agents',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
