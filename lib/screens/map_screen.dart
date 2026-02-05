import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:FruitCapitals/screens/hileras_screen.dart';
import 'package:FruitCapitals/screens/observaciones_list_screen.dart';
import 'package:FruitCapitals/screens/observation_screen.dart';
import 'package:FruitCapitals/screens/reporte_zona_screen.dart';
import 'package:FruitCapitals/services/connectivity_service.dart';
import 'package:FruitCapitals/services/observation_repository.dart';
import 'package:FruitCapitals/services/observation_sync_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../services/firestore_service.dart';
import '../models/cuartel.dart';
import '../utils/polygon_utils.dart';
import 'dart:io';

import '../screens/cuarteles_list_screen.dart';
import '../models/observation.dart';
import 'package:firebase_auth/firebase_auth.dart';



class MapScreen extends StatefulWidget {
  final bool showNuevaObservacion;

  const MapScreen({
    super.key,
    this.showNuevaObservacion = true,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  final List<LatLng> _currentPolygonPoints = [];
  final Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Marker> _observationMarkers = {};
  final user = FirebaseAuth.instance.currentUser;

  final FirestoreService _firestoreService = FirestoreService();

  String _searchText = '';
  List<Cuartel> _allCuarteles = [];


  bool _saving = false;
  bool _creating = false;
  bool _isOffline = false;
  bool _isSyncing = false;
  bool _showStatusBanner = true;
  bool isEmpleado = true;

  Cuartel? _selectedCuartel;

  final observationRepo = ObservationRepository();
  final connectivity = ConnectivityService();
  
  void _startCreateCuartel() {
    _startCreating();
  }

  void _closeCuartel() {
    if (_creating) {
      if (_currentPolygonPoints.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agrega al menos 3 puntos para cerrar el cuartel'),
          ),
        );
        return;
      }
      _showCuartelForm();
      return;
    }

    setState(() {
      _selectedCuartel = null;
      _buildPolygons();
    });
  }

  Future<void> _centerOnUser() async {
    if (_mapController == null) return;
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {
      return;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        17,
      ),
    );
  }

  Future<void> _zoomIn() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(CameraUpdate.zoomOut());
  }

  void initSyncListener() {
    connectivity.onConnectionChange.listen((result) async {
      final nowOffline = result == ConnectivityResult.none;

      if (nowOffline) {
        setState(() {
          _isOffline = true;
          _isSyncing = false;
          _showStatusBanner = true;
        });
      } else {
        setState(() {
          _isOffline = false;
          _isSyncing = true;
          _showStatusBanner = true;
        });

        await observationRepo.syncObservations();

        if (!mounted) return;

        setState(() {
          _isSyncing = false;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _showStatusBanner = false;
          });
        });
      }
    });
  }

  void _buildPolygons() {
    _polygons = _allCuarteles
        .where((c) =>
            c.nombre.toLowerCase().contains(_searchText.toLowerCase()))
        .map((cuartel) {
      final bool isSelected = _selectedCuartel?.id == cuartel.id;

      return Polygon(
        polygonId: PolygonId(cuartel.id),
        points: cuartel.puntos,
        fillColor: isSelected
            ? Colors.orange.withOpacity(0.45)
            : Colors.green.withOpacity(0.25),
        strokeColor: isSelected ? Colors.deepOrange : Colors.green,
        strokeWidth: isSelected ? 4 : 2,
        consumeTapEvents: true,
        onTap: () => _onCuartelTap(cuartel),
      );
    }).toSet();
  }

  void _loadObservations() {
    FirestoreService().getObservaciones().listen((observations) {
      final markers = observations.map((obs) {
        return Marker(
          markerId: MarkerId(
            '${obs.latitude}_${obs.longitude}_${obs.createdAt.millisecondsSinceEpoch}',
          ),
          position: LatLng(obs.latitude, obs.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: () => _onObservationTap(obs),
        );
      }).toSet();

      setState(() {
        _observationMarkers = markers;
      });
    });
  }

  void _onObservationTap(Observation obs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  obs.description.isEmpty
                      ? 'Observación sin texto'
                      : obs.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (obs.cuartelNombre != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.map, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        obs.cuartelNombre!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 8),

                Text(
                  'Lat: ${obs.latitude.toStringAsFixed(5)}\nLng: ${obs.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 12),
                if (obs.photoPaths.isEmpty)
                const Text(
                  'Sin fotos asociadas',
                  style: TextStyle(color: Colors.grey),
                ),

                if (obs.photoPaths.isNotEmpty) ...[
                  const Text(
                    'Fotos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: obs.photoPaths.length,
                      itemBuilder: (_, index) {
                        final photoPath = obs.photoPaths[index];

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: photoPath.startsWith('http')
                                ? Image.network(
                                    photoPath,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(photoPath),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        );
                      },
                    ),
                  )
                ] else ...[
                  const Text(
                    'Sin fotos',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _focusCuartel(Cuartel cuartel) {
    if (cuartel.puntos.isEmpty) return;
    if (!mounted || _mapController == null) return;

    final center = cuartel.puntos.first;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(center, 17),
    );

    setState(() {
      _selectedCuartel = cuartel;
      _creating = false;
      _markers.clear();
      _currentPolygonPoints.clear();
      _buildPolygons();
    });
  }

  void _showEditCuartelForm(Cuartel cuartel) {
    final nombreCtrl = TextEditingController(text: cuartel.nombre);
    final cultivoCtrl = TextEditingController(text: cuartel.cultivo);
    final variedadCtrl = TextEditingController(text: cuartel.variedad);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Editar cuartel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cultivoCtrl,
              decoration: const InputDecoration(labelText: 'Cultivo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: variedadCtrl,
              decoration: const InputDecoration(labelText: 'Variedad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();

              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El nombre es requerido'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await _firestoreService.updateCuartel(
                  id: cuartel.id,
                  nombre: nombre,
                  cultivo: cultivoCtrl.text.trim(),
                  variedad: variedadCtrl.text.trim(),
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Cuartel actualizado'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );

                setState(() {
                  _selectedCuartel = null;
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadObservations();
    initSyncListener();
    _loadUserRole();
    ObservationSyncService().syncPendingObservations();

    ConnectivityService().onConnectionChange.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });

    FirestoreService().getCuarteles().listen((cuarteles) {
      if (!mounted) return;

      setState(() {
        _allCuarteles = cuarteles;
        _buildPolygons();
      });
    });

    ConnectivityService().hasConnection().then((online) {
      setState(() {
        _isOffline = !online;
      });
    });
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final role = await _firestoreService.getUserRole(uid);

    if (!mounted) return;

    setState(() {
      isEmpleado = role == 'empleado';
    });
  }


  void _startCreating() {
    setState(() {
      _creating = true;
      _selectedCuartel = null;
      _currentPolygonPoints.clear();
      _markers.clear();
      _buildPolygons();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Toca el mapa para comenzar a crear el cuartel'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetEdition() {
    setState(() {
      _creating = false;
      _currentPolygonPoints.clear();
      _markers.clear();
      _selectedCuartel = null;
      _saving = false;
      _buildPolygons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isJefeView = !isEmpleado;
    final scheme = Theme.of(context).colorScheme;
    final mapPadding = const EdgeInsets.only(
      top: 140,
      bottom: 160,
      right: 12,
      left: 12,
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.satellite,
            padding: mapPadding,

            initialCameraPosition: const CameraPosition(
              target: LatLng(-33.45, -70.66),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            polygons: _polygons,
            markers: {
              ..._markers, 
              ..._observationMarkers,
            },
            onTap: (position) {
              if (_creating) {
                setState(() {
                  _currentPolygonPoints.add(position);
                  _markers.add(
                    Marker(
                      markerId: MarkerId(position.toString()),
                      position: position,
                    ),
                  );
                });
              } else {
                setState(() {
                  _selectedCuartel = null;
                  _buildPolygons();
                });
              }
            },
            onMapCreated: (controller) async {
              _mapController = controller;

              if (!await Permission.location.isGranted) {
                await Permission.location.request();
              }

              Position pos;
              try {
                pos = await Geolocator.getCurrentPosition();
              } catch (_) {
                return;
              }

              if (!mounted || _mapController == null) return;

              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(pos.latitude, pos.longitude),
                  17,
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar cuartel...',
                  prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _buildPolygons();
                  });
                },
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              offset: _showStatusBanner ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showStatusBanner ? 1 : 0,
                child: _buildStatusBanner(),
              ),
            ),
          ),

          if (_selectedCuartel != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _CuartelInfoBox(
                cuartel: _selectedCuartel!,
                isEmpleado: isEmpleado,
                onClose: () {
                  setState(() {
                    _selectedCuartel = null;
                    _buildPolygons();
                  });
                },
                onDelete: () => _deleteCuartel(_selectedCuartel!),
                onEdit: () => _showEditCuartelForm(_selectedCuartel!),
              ),
            ),

          if (_creating)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_location, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Creando cuartel (${_currentPolygonPoints.length} puntos)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _resetEdition,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 140,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center_me',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showNuevaObservacion) ...[
                  _buildActionFab(
                    heroTag: 'obs',
                    color: scheme.primary,
                    icon: Icons.note_add,
                    label: 'Nueva informacion',
                    compact: isJefeView,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ObservationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (!isEmpleado) ...[
                  const SizedBox(height: 10),
                  _buildActionFab(
                    heroTag: 'crear',
                    color: scheme.primary,
                    icon: Icons.add,
                    label: 'Crear cuartel',
                    compact: isJefeView,
                    onPressed: _startCreateCuartel,
                  ),
                  const SizedBox(height: 10),
                  _buildActionFab(
                    heroTag: 'cerrar',
                    color: scheme.error,
                    icon: Icons.close,
                    label: 'Cerrar cuartel',
                    compact: isJefeView,
                    onPressed:
                        (!_creating && _selectedCuartel == null) ? null : _closeCuartel,
                  ),
                  const SizedBox(height: 10),
                  _buildActionFab(
                    heroTag: 'reporte',
                    color: scheme.tertiary,
                    icon: Icons.bar_chart,
                    label: 'Reporte por zona',
                    compact: isJefeView,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReporteZonaScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildActionFab({
    required String heroTag,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool compact = false,
  }) {
    final Color bg = color;
    final Color fg = Colors.white;
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: bg,
      elevation: compact ? 8 : 6,
      shape: const StadiumBorder(),
      icon: Icon(icon, color: fg, size: compact ? 20 : 24),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 12 : 14,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildStatusBanner() {
    Color color;
    String text;
    IconData icon;

    if (_isSyncing) {
      color = Colors.blue;
      text = 'Sincronizando observaciones...';
      icon = Icons.sync;
    } else if (_isOffline) {
      color = Colors.red;
      text = 'Modo offline: datos guardados localmente';
      icon = Icons.cloud_off;
    } else {
      color = Colors.green;
      text = 'Conectado a la nube';
      icon = Icons.cloud_done;
    }

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCuartelForm() {
    final nombreCtrl = TextEditingController();
    final cultivoCtrl = TextEditingController();
    final variedadCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo cuartel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cultivoCtrl,
              decoration: const InputDecoration(labelText: 'Cultivo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: variedadCtrl,
              decoration: const InputDecoration(labelText: 'Variedad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetEdition();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('El nombre es requerido'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              setState(() => _saving = true);

              try {
                final ordered = sortPointsClockwise(
                  List.from(_currentPolygonPoints),
                );

                print('Guardando cuartel: $nombre con ${ordered.length} puntos');

                await _firestoreService.saveCuartel(
                  nombre: nombre,
                  cultivo: cultivoCtrl.text.trim(),
                  variedad: variedadCtrl.text.trim(),
                  puntos: ordered,
                );

                print('Cuartel guardado exitosamente');

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Cuartel guardado exitosamente'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    duration: Duration(seconds: 2),
                  ),
                );

                _resetEdition();
                
                print('Estado reseteado, listo para crear otro');
                
              } catch (e) {
                print('Error al guardar: $e');
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al guardar: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                setState(() => _saving = false);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _onCuartelTap(Cuartel c) {
    print('_onCuartelTap llamado para: ${c.nombre}');
    
    setState(() {
      _creating = false;
      _currentPolygonPoints.clear();
      _markers.clear();
      _selectedCuartel = c;
      _buildPolygons();
    });
    
    print('Estado actualizado, selectedCuartel: ${_selectedCuartel?.nombre}');
  }

  void _deleteCuartel(Cuartel cuartel) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuartel'),
        content: Text('¿Estás seguro de que deseas eliminar el cuartel "${cuartel.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _selectedCuartel = null;
              });
              
              try {
                await _firestoreService.deleteCuartel(cuartel.id);
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Cuartel eliminado exitosamente'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

}

class _CuartelInfoBox extends StatelessWidget {
  final Cuartel cuartel;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isEmpleado;


  const _CuartelInfoBox({
    required this.cuartel,
    required this.onClose,
    required this.onDelete,
    required this.onEdit,
    required this.isEmpleado,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cuartel.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16, thickness: 2, color: Colors.green),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.agriculture, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cultivo: ${cuartel.cultivo}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.spa, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Variedad: ${cuartel.variedad}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            if (!isEmpleado) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar cuartel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 20),
                  label: const Text('Eliminar cuartel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            if (isEmpleado) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.view_list),
                  label: const Text('Hileras'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HilerasScreen(
                          cuartelId: cuartel.id,
                          cuartelNombre: cuartel.nombre,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid(List<String> photos) {
    if (photos.isEmpty) {
      return const Text(
        'Sin fotos asociadas',
        style: TextStyle(color: Colors.grey),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        final path = photos[index];
        final file = File(path);

        if (!file.existsSync()) {
          return const Icon(Icons.broken_image);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
