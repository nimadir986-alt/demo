import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HeatLossApp());
}

class HeatLossApp extends StatelessWidget {
  const HeatLossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Теплопотери калькулятори',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07161C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF27E1B5),
          secondary: Color(0xFF3DD6C6),
          surface: Color(0xFF10252D),
          error: Color(0xFFFF5252),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D2027),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF203B44)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF203B44)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF50EED0)),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      home: const MainNavigationPage(),
    );
  }
}

class NavTabItem {
  final IconData icon;
  final String label;

  const NavTabItem({
    required this.icon,
    required this.label,
  });
}

enum CalcItemKind {
  overall,
  externalWall,
  externalWindow,
  externalDoor,
  column,
  rigel,
  soilZone,
  floor,
  ceiling,
}

class CalcMenuItem {
  final String id;
  final String title;
  final CalcItemKind kind;

  const CalcMenuItem({
    required this.id,
    required this.title,
    required this.kind,
  });
}

class CalcMenuGroup {
  final String id;
  final String title;
  final List<CalcMenuItem> items;

  const CalcMenuGroup({
    required this.id,
    required this.title,
    required this.items,
  });
}

enum FacingDirection {
  south,
  southWest,
  west,
  southEast,
  north,
  east,
  northWest,
  northEast,
  none,
}

extension FacingDirectionX on FacingDirection {
  String get title {
    switch (this) {
      case FacingDirection.south:
        return 'Жануб';
      case FacingDirection.southWest:
        return 'Жанубий-Ғарб';
      case FacingDirection.west:
        return 'Ғарб';
      case FacingDirection.southEast:
        return 'Жанубий-Шарқ';
      case FacingDirection.north:
        return 'Шимол';
      case FacingDirection.east:
        return 'Шарқ';
      case FacingDirection.northWest:
        return 'Шимолий-Ғарб';
      case FacingDirection.northEast:
        return 'Шимолий-Шарқ';
      case FacingDirection.none:
        return '—';
    }
  }
}

extension CalcItemKindX on CalcItemKind {
  bool get usesOrientation {
    switch (this) {
      case CalcItemKind.externalWall:
      case CalcItemKind.externalWindow:
      case CalcItemKind.externalDoor:
      case CalcItemKind.column:
      case CalcItemKind.rigel:
        return true;
      default:
        return false;
    }
  }

  bool get usesN {
    switch (this) {
      case CalcItemKind.soilZone:
        return false;
      case CalcItemKind.overall:
        return false;
      default:
        return true;
    }
  }

  double get defaultR {
    switch (this) {
      case CalcItemKind.externalWall:
      case CalcItemKind.externalWindow:
      case CalcItemKind.externalDoor:
      case CalcItemKind.column:
      case CalcItemKind.rigel:
      case CalcItemKind.floor:
      case CalcItemKind.ceiling:
        return 1.0;
      case CalcItemKind.soilZone:
        return 1.0;
      case CalcItemKind.overall:
        return 1.0;
    }
  }
}

double orientationCoefficient(FacingDirection direction) {
  switch (direction) {
    case FacingDirection.west:
    case FacingDirection.southEast:
      return 0.05;
    case FacingDirection.south:
    case FacingDirection.southWest:
      return 0.0;
    case FacingDirection.north:
    case FacingDirection.east:
    case FacingDirection.northWest:
    case FacingDirection.northEast:
      return 0.10;
    case FacingDirection.none:
      return 0.0;
  }
}
enum AirLayerThickness {
  none,
  t01,
  t02,
  t03,
  t05,
  t10,
  t15,
  t20_30,
}

enum AirLayerSign {
  positive,
  negative,
}

extension AirLayerThicknessX on AirLayerThickness {
  String get title {
    switch (this) {
      case AirLayerThickness.none:
        return 'Йўқ';
      case AirLayerThickness.t01:
        return '0,01';
      case AirLayerThickness.t02:
        return '0,02';
      case AirLayerThickness.t03:
        return '0,03';
      case AirLayerThickness.t05:
        return '0,05';
      case AirLayerThickness.t10:
        return '0,10';
      case AirLayerThickness.t15:
        return '0,15';
      case AirLayerThickness.t20_30:
        return '0,2–0,3';
    }
  }
}

extension AirLayerSignX on AirLayerSign {
  String get title {
    switch (this) {
      case AirLayerSign.positive:
        return 'Ижобий (+)';
      case AirLayerSign.negative:
        return 'Салбий (-)';
    }
  }
}

bool supportsAirLayerResistance(CalcItemKind kind) {
  return kind == CalcItemKind.externalWall ||
      kind == CalcItemKind.column ||
      kind == CalcItemKind.rigel ||
      kind == CalcItemKind.ceiling ||
      kind == CalcItemKind.floor;
}

bool usesFloorAirLayerTable(CalcItemKind kind) {
  return kind == CalcItemKind.floor;
}

double airLayerResistanceValue({
  required CalcItemKind kind,
  required AirLayerThickness thickness,
  required AirLayerSign sign,
}) {
  final bool isFloor = usesFloorAirLayerTable(kind);

  switch (thickness) {
    case AirLayerThickness.none:
      return 0.0;

    case AirLayerThickness.t01:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.14 : 0.15)
          : (sign == AirLayerSign.positive ? 0.13 : 0.15);

    case AirLayerThickness.t02:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.15 : 0.19)
          : (sign == AirLayerSign.positive ? 0.14 : 0.15);

    case AirLayerThickness.t03:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.16 : 0.21)
          : (sign == AirLayerSign.positive ? 0.14 : 0.16);

    case AirLayerThickness.t05:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.17 : 0.22)
          : (sign == AirLayerSign.positive ? 0.14 : 0.17);

    case AirLayerThickness.t10:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.18 : 0.23)
          : (sign == AirLayerSign.positive ? 0.15 : 0.18);

    case AirLayerThickness.t15:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.19 : 0.24)
          : (sign == AirLayerSign.positive ? 0.15 : 0.18);

    case AirLayerThickness.t20_30:
      return isFloor
          ? (sign == AirLayerSign.positive ? 0.19 : 0.24)
          : (sign == AirLayerSign.positive ? 0.15 : 0.19);
  }
}
double? soilZoneResistanceById(String id) {
  switch (id) {
    case 'soil_zone_1':
      return 2.21;
    case 'soil_zone_2':
      return 4.41;
    case 'soil_zone_3':
      return 8.71;
    case 'soil_zone_4':
      return 14.31;
    default:
      return null;
  }
}

enum InfiltrationKOption {
  tightPanels,
  windowsAndBalcony,
  oneWindowOpenTop,
}

extension InfiltrationKOptionX on InfiltrationKOption {
  String get title {
    switch (this) {
      case InfiltrationKOption.tightPanels:
        return 'Девор панеллари ва деразаларнинг бўғинлари — яхши бирлаштирилган панеллар, эшик ва дераза ромлари';
      case InfiltrationKOption.windowsAndBalcony:
        return 'Дераза ва балкон эшиклари — очилиши мумкин бўлган конструкциялар ва жойлар';
      case InfiltrationKOption.oneWindowOpenTop:
        return '1 та дераза ёки балкон эшиги тепа ёки ён томони очиқ';
    }
  }

  double get kValue {
    switch (this) {
      case InfiltrationKOption.tightPanels:
        return 0.7;
      case InfiltrationKOption.windowsAndBalcony:
        return 0.8;
      case InfiltrationKOption.oneWindowOpenTop:
        return 1.0;
    }
  }
}

/// 3-жадвал: t -> Gi
double giByIndoorTemp(int tempEven) {
  const table = <int, double>{
    0: 1.293,
    2: 1.283,
    4: 1.274,
    6: 1.265,
    8: 1.256,
    10: 1.247,
    12: 1.238,
    14: 1.229,
    16: 1.221,
    18: 1.212,
    20: 1.204,
    22: 1.196,
    24: 1.188,
    26: 1.180,
    28: 1.172,
    30: 1.164,
    32: 1.157,
  };

  final int clamped = tempEven.clamp(0, 32).toInt();
return table[clamped]!;
}

int normalizeIndoorTempForGi(double temp) {
  int t = temp.floor();
  if (t.isOdd) t -= 1;
  if (t < 0) t = 0;
  if (t > 32) t = 32;
  return t;
}


class ElementSnapshot {
  final String height;
  final String length;
  final String indoorTemp;
  final String outdoorTemp;
  final String betaSum;
  final String rValue;
  final String nValue;
  final FacingDirection direction;

  final String attachedWallId; // <-- янги
  final AirLayerThickness airLayerThickness;
final AirLayerSign airLayerSign;

  const ElementSnapshot({
    required this.height,
    required this.length,
    required this.indoorTemp,
    required this.outdoorTemp,
    required this.betaSum,
    required this.rValue,
    required this.nValue,
    required this.direction,
    required this.attachedWallId, // <-- янги
    required this.airLayerThickness,
required this.airLayerSign,
  });

  

  factory ElementSnapshot.defaults(CalcMenuItem item) {
    String n = item.kind.usesN ? '1' : '';

final soilR = soilZoneResistanceById(item.id);
final String r = soilR != null ? soilR.toString() : '1';

    return ElementSnapshot(
  height: '',
  length: '',
  indoorTemp: '20',
  outdoorTemp: '-15',
  betaSum: '',
  rValue: r,
  nValue: n,
  direction: item.kind.usesOrientation
      ? FacingDirection.south
      : FacingDirection.none,
  attachedWallId: 'external_wall_1',
  airLayerThickness: AirLayerThickness.none,
  airLayerSign: AirLayerSign.positive,
);
  }
}

class ElementRecord {
  final ElementSnapshot draft;
  final double? savedQ;

  const ElementRecord({
    required this.draft,
    this.savedQ,
  });
}

class ElementState {
  final CalcMenuItem item;

  final TextEditingController heightController;
  final TextEditingController lengthController;
  final TextEditingController indoorTempController;
  final TextEditingController outdoorTempController;
  final TextEditingController betaSumController;
  final TextEditingController rController;
  final TextEditingController nController;

  FacingDirection direction;
  String attachedWallId;
  AirLayerThickness airLayerThickness;
  AirLayerSign airLayerSign;
  double? savedQ;

  ElementState({
    required this.item,
    required ElementSnapshot snapshot,
    this.savedQ,
  })  : heightController = TextEditingController(text: snapshot.height),
        lengthController = TextEditingController(text: snapshot.length),
        indoorTempController = TextEditingController(text: snapshot.indoorTemp),
        outdoorTempController = TextEditingController(text: snapshot.outdoorTemp),
        betaSumController = TextEditingController(text: snapshot.betaSum),
        rController = TextEditingController(text: snapshot.rValue),
        nController = TextEditingController(text: snapshot.nValue),
        direction = snapshot.direction,
        attachedWallId = snapshot.attachedWallId,
        airLayerThickness = snapshot.airLayerThickness,
        airLayerSign = snapshot.airLayerSign;

  ElementSnapshot toSnapshot() {
    return ElementSnapshot(
      height: heightController.text,
      length: lengthController.text,
      indoorTemp: indoorTempController.text,
      outdoorTemp: outdoorTempController.text,
      betaSum: betaSumController.text,
      rValue: rController.text,
      nValue: nController.text,
      direction: direction,
      attachedWallId: attachedWallId,
      airLayerThickness: airLayerThickness,
      airLayerSign: airLayerSign,
    );
  }

  void bind(VoidCallback listener) {
    heightController.addListener(listener);
    lengthController.addListener(listener);
    indoorTempController.addListener(listener);
    outdoorTempController.addListener(listener);
    betaSumController.addListener(listener);
    rController.addListener(listener);
    nController.addListener(listener);
  }

  void dispose() {
    heightController.dispose();
    lengthController.dispose();
    indoorTempController.dispose();
    outdoorTempController.dispose();
    betaSumController.dispose();
    rController.dispose();
    nController.dispose();
  }
}
  

class ElementCalculationResult {
  final bool isReady;
  final String? error;
  final double grossArea;
  final double netArea;
  final double? deltaT;
  final double? betaSum;
  final double orientationBeta;
  final double? rValue;
  final double? nValue;
  final double? firstBracket;
  final double? secondBracket;
  final double? q;

  const ElementCalculationResult({
    required this.isReady,
    required this.error,
    required this.grossArea,
    required this.netArea,
    required this.deltaT,
    required this.betaSum,
    required this.orientationBeta,
    required this.rValue,
    required this.nValue,
    required this.firstBracket,
    required this.secondBracket,
    required this.q,
  });

  const ElementCalculationResult.empty()
      : isReady = false,
        error = null,
        grossArea = 0,
        netArea = 0,
        deltaT = null,
        betaSum = null,
        orientationBeta = 0,
        rValue = null,
        nValue = null,
        firstBracket = null,
        secondBracket = null,
        q = null;
}

class ProjectRecord {
  final String slotTitle;
  final String floorNumber;
  final String roomNumber;
  final String roomName;
  final String roomHeight;
  final String infiltration;
  final Map<String, ElementRecord> elementRecords;
  final DateTime? savedAt;
  final double totalSavedQ;

  const ProjectRecord({
    required this.slotTitle,
    this.floorNumber = '0',
    this.roomNumber = '0',
    this.roomName = '',
    this.roomHeight = '3',
    this.infiltration = '0',
    this.elementRecords = const {},
    this.savedAt,
    this.totalSavedQ = 0,
  });

  bool get isSaved =>
      savedAt != null || elementRecords.values.any((e) => e.savedQ != null);

  ProjectRecord copyWith({
    String? floorNumber,
    String? roomNumber,
    String? roomName,
    String? roomHeight,
    String? infiltration,
    Map<String, ElementRecord>? elementRecords,
    DateTime? savedAt,
    double? totalSavedQ,
  }) {
    return ProjectRecord(
      slotTitle: slotTitle,
      floorNumber: floorNumber ?? this.floorNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      roomName: roomName ?? this.roomName,
      roomHeight: roomHeight ?? this.roomHeight,
      infiltration: infiltration ?? this.infiltration,
      elementRecords: elementRecords ?? this.elementRecords,
      savedAt: savedAt ?? this.savedAt,
      totalSavedQ: totalSavedQ ?? this.totalSavedQ,
    );
  }
}

class OverallSavedSummary {
  final double externalWall;
  final double externalWindow;
  final double externalDoor;
  final double column;
  final double rigel;
  final double soil;
  final double floor;
  final double ceiling;
  final double qTos;
  final double infiltration;
  final double overall;

  const OverallSavedSummary({
    required this.externalWall,
    required this.externalWindow,
    required this.externalDoor,
    required this.column,
    required this.rigel,
    required this.soil,
    required this.floor,
    required this.ceiling,
    required this.qTos,
    required this.infiltration,
    required this.overall,
  });
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 1;
  int _selectedProjectIndex = 0;

  late final List<ProjectRecord> _projects = List.generate(
    50,
    (index) => ProjectRecord(slotTitle: 'Лойиҳа ${index + 1}'),
  );

  ProjectRecord get _activeProject => _projects[_selectedProjectIndex];

  void _selectProject(int index) {
    setState(() {
      _selectedProjectIndex = index;
      _currentIndex = 1;
    });
  }

  void _saveProject(ProjectRecord updated) {
    setState(() {
      _projects[_selectedProjectIndex] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProjectsScreen(
        projects: _projects,
        selectedProjectIndex: _selectedProjectIndex,
        onSelectProject: _selectProject,
      ),
      CalculatorScreen(
        key: ValueKey(
          '${_selectedProjectIndex}_${_activeProject.savedAt?.millisecondsSinceEpoch ?? 0}',
        ),
        projectIndex: _selectedProjectIndex,
        initialProject: _activeProject,
        onSaveProject: _saveProject,
      ),
      const ReferenceScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    const items = [
      NavTabItem(
        icon: Icons.dashboard_customize_rounded,
        label: 'Лойиҳалар',
      ),
      NavTabItem(
        icon: Icons.calculate_outlined,
        label: 'Калькулятор',
      ),
      NavTabItem(
        icon: Icons.layers_outlined,
        label: 'Маълумотнома',
      ),
      NavTabItem(
        icon: Icons.settings_outlined,
        label: 'Созламалар',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1C22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E3841)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = _currentIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _currentIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected ? const Color(0xFF112B33) : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF4EF0D1)
                          : Colors.white54,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : Colors.white54,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final int projectIndex;
  final ProjectRecord initialProject;
  final ValueChanged<ProjectRecord> onSaveProject;

  const CalculatorScreen({
    super.key,
    required this.projectIndex,
    required this.initialProject,
    required this.onSaveProject,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _floorNumberController = TextEditingController();
final TextEditingController _roomNumberController = TextEditingController();
final TextEditingController _roomNameController = TextEditingController();
final TextEditingController _roomHeightController = TextEditingController();

final TextEditingController _infiltrationTempController =
    TextEditingController(text: '20');

InfiltrationKOption _selectedInfiltrationK =
    InfiltrationKOption.tightPanels;

  String _selectedCalcItemId = 'overall';

  late final List<CalcMenuGroup> _calcGroups = const [
    CalcMenuGroup(
      id: 'external_wall',
      title: 'Ташқи девор',
      items: [
        CalcMenuItem(
          id: 'external_wall_1',
          title: 'Ташқи девор - 1',
          kind: CalcItemKind.externalWall,
        ),
        CalcMenuItem(
          id: 'external_wall_2',
          title: 'Ташқи девор - 2',
          kind: CalcItemKind.externalWall,
        ),
      ],
    ),
    CalcMenuGroup(
      id: 'external_window',
      title: 'Ташқи дераза',
      items: [
        CalcMenuItem(
          id: 'external_window_1',
          title: 'Ташқи дераза - 1',
          kind: CalcItemKind.externalWindow,
        ),
        CalcMenuItem(
          id: 'external_window_2',
          title: 'Ташқи дераза - 2',
          kind: CalcItemKind.externalWindow,
        ),
      ],
    ),
    CalcMenuGroup(
      id: 'external_door',
      title: 'Ташқи эшик',
      items: [
        CalcMenuItem(
          id: 'external_door_1',
          title: 'Ташқи эшик - 1',
          kind: CalcItemKind.externalDoor,
        ),
        CalcMenuItem(
          id: 'external_door_2',
          title: 'Ташқи эшик - 2',
          kind: CalcItemKind.externalDoor,
        ),
      ],
    ),
    CalcMenuGroup(
      id: 'column',
      title: 'Колонна',
      items: [
        CalcMenuItem(
          id: 'column_1',
          title: 'Колонна - 1',
          kind: CalcItemKind.column,
        ),
        CalcMenuItem(
          id: 'column_2',
          title: 'Колонна - 2',
          kind: CalcItemKind.column,
        ),
      ],
    ),
    CalcMenuGroup(
      id: 'rigel',
      title: 'Ригел',
      items: [
        CalcMenuItem(
          id: 'rigel_1',
          title: 'Ригел - 1',
          kind: CalcItemKind.rigel,
        ),
        CalcMenuItem(
          id: 'rigel_2',
          title: 'Ригел - 2',
          kind: CalcItemKind.rigel,
        ),
      ],
    ),
    CalcMenuGroup(
      id: 'soil_zone',
      title: 'Тупроқ тўсиқлари',
      items: [
        CalcMenuItem(
          id: 'soil_zone_1',
          title: 'Тупроқ тўсиқлари 1 зона',
          kind: CalcItemKind.soilZone,
        ),
        CalcMenuItem(
          id: 'soil_zone_2',
          title: 'Тупроқ тўсиқлари 2 зона',
          kind: CalcItemKind.soilZone,
        ),
        CalcMenuItem(
          id: 'soil_zone_3',
          title: 'Тупроқ тўсиқлари 3 зона',
          kind: CalcItemKind.soilZone,
        ),
        CalcMenuItem(
          id: 'soil_zone_4',
          title: 'Тупроқ тўсиқлари 4 зона',
          kind: CalcItemKind.soilZone,
        ),
      ],
    ),
  ];

  late final List<CalcMenuItem> _singleItems = const [
    CalcMenuItem(
      id: 'floor_single',
      title: 'Пол',
      kind: CalcItemKind.floor,
    ),
    CalcMenuItem(
      id: 'ceiling_single',
      title: 'Потолок',
      kind: CalcItemKind.ceiling,
    ),
  ];

  late final Map<String, CalcMenuItem> _itemMap;
  late final Map<String, ElementState> _elements;

  @override
  void initState() {
    super.initState();

    _itemMap = {
      for (final group in _calcGroups)
        for (final item in group.items) item.id: item,
      for (final item in _singleItems) item.id: item,
    };

    _loadProject(widget.initialProject);

    _floorNumberController.addListener(_refresh);
    _roomNumberController.addListener(_refresh);
    _roomNameController.addListener(_refresh);
    _roomHeightController.addListener(_refresh);
    _infiltrationTempController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _loadProject(ProjectRecord project) {
    _floorNumberController.text = project.floorNumber;
    _roomNumberController.text = project.roomNumber;
    _roomNameController.text = project.roomName;
    _roomHeightController.text = project.roomHeight;
    _infiltrationTempController.text = project.infiltration;

    _elements = {};
    _itemMap.forEach((id, item) {
      final record = project.elementRecords[id];
      final snapshot = record?.draft ?? ElementSnapshot.defaults(item);

      final state = ElementState(
        item: item,
        snapshot: snapshot,
        savedQ: record?.savedQ,
      );

      state.bind(_refresh);
      _elements[id] = state;
    });
  }

  @override
  void dispose() {
    _floorNumberController.dispose();
    _roomNumberController.dispose();
    _roomNameController.dispose();
    _roomHeightController.dispose();
    _infiltrationTempController.dispose();

    for (final element in _elements.values) {
      element.dispose();
    }

    super.dispose();
  }

  double? _parse(String value) {
    final cleaned = value.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  double _parseOrZero(String value) => _parse(value) ?? 0.0;

  String _fmtDouble(double value, {int digits = 2}) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(digits);
}

double _maxPositiveDeltaTForInfiltration() {
  final snapshots = _workingSnapshots();
  double maxDt = 0.0;

  for (final entry in snapshots.entries) {
    final snapshot = entry.value;
    final ti = _parse(snapshot.indoorTemp);
    final tt = _parse(snapshot.outdoorTemp);

    if (ti == null || tt == null) continue;

    final dt = ti - tt;
    if (dt > maxDt) {
      maxDt = dt;
    }
  }

  return maxDt;
}

double _calculateOverallInfiltration() {
  final double height = _parseOrZero(_roomHeightController.text);
  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);

  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltration();
  final double k = _selectedInfiltrationK.kValue;

  if (height <= 0 || maxDt <= 0) return 0.0;

  return 0.28 * 1.005 * (height * gi) * maxDt * k;
}

Map<String, ElementSnapshot> _workingSnapshots() {
    return {
      for (final entry in _elements.entries) entry.key: entry.value.toSnapshot(),
    };
  }

  double _grossAreaFromSnapshot(ElementSnapshot snapshot) {
    final h = _parseOrZero(snapshot.height);
    final l = _parseOrZero(snapshot.length);
    return h * l;
  }

  double _totalOpeningArea(Map<String, ElementSnapshot> snapshots) {
    double sum = 0;

    for (final entry in snapshots.entries) {
      final kind = _itemMap[entry.key]!.kind;
      if (kind == CalcItemKind.externalWindow ||
          kind == CalcItemKind.externalDoor ||
          kind == CalcItemKind.column ||
          kind == CalcItemKind.rigel) {
        sum += _grossAreaFromSnapshot(entry.value);
      }
    }

    return sum;
  }

  double _totalExternalWallGrossArea(Map<String, ElementSnapshot> snapshots) {
    double sum = 0;

    for (final entry in snapshots.entries) {
      final kind = _itemMap[entry.key]!.kind;
      if (kind == CalcItemKind.externalWall) {
        sum += _grossAreaFromSnapshot(entry.value);
      }
    }

    return sum;
  }

  bool _isSubtractedFromWall(CalcItemKind kind) {
  return kind == CalcItemKind.externalWindow ||
      kind == CalcItemKind.externalDoor ||
      kind == CalcItemKind.column ||
      kind == CalcItemKind.rigel;
}

double _openingAreaForWall(
  String wallId,
  Map<String, ElementSnapshot> snapshots,
) {
  double sum = 0.0;

  for (final entry in snapshots.entries) {
    final item = _itemMap[entry.key]!;
    final snapshot = entry.value;

    if (_isSubtractedFromWall(item.kind) &&
        snapshot.attachedWallId == wallId) {
      sum += _grossAreaFromSnapshot(snapshot);
    }
  }

  return sum;
}

  double _netAreaFor(String id, Map<String, ElementSnapshot> snapshots) {
  final item = _itemMap[id]!;
  final snapshot = snapshots[id]!;

  final double gross = _grossAreaFromSnapshot(snapshot);

  if (item.kind != CalcItemKind.externalWall) {
    return gross;
  }

  final double deducted = _openingAreaForWall(id, snapshots);
  final double net = math.max(0.0, gross - deducted).toDouble();

  return net;
}

 ElementCalculationResult _calculateFor(
  String id,
  Map<String, ElementSnapshot> snapshots,
) {
  final item = _itemMap[id]!;
  final snapshot = snapshots[id]!;

  final double gross = _grossAreaFromSnapshot(snapshot);
  final double net = _netAreaFor(id, snapshots);

  final double? ti = _parse(snapshot.indoorTemp);
  final double? tt = _parse(snapshot.outdoorTemp);
  final double? beta = _parse(snapshot.betaSum);
  final double? n = _parse(snapshot.nValue);

  final double? forcedSoilR = soilZoneResistanceById(id);
  final double? baseR = forcedSoilR ?? _parse(snapshot.rValue);

  final double airLayerR = supportsAirLayerResistance(item.kind)
      ? airLayerResistanceValue(
          kind: item.kind,
          thickness: snapshot.airLayerThickness,
          sign: snapshot.airLayerSign,
        )
      : 0.0;

  final double? r = baseR == null ? null : baseR + airLayerR;

  final double? deltaT = (ti != null && tt != null) ? (ti - tt) : null;

  final double orientationBeta = item.kind.usesOrientation
      ? orientationCoefficient(snapshot.direction)
      : 0.0;

  if (net <= 0) {
    return ElementCalculationResult(
      isReady: false,
      error: 'Юза 0 дан катта бўлиши керак',
      grossArea: gross,
      netArea: net,
      deltaT: deltaT,
      betaSum: beta,
      orientationBeta: orientationBeta,
      rValue: r,
      nValue: n,
      firstBracket: null,
      secondBracket: null,
      q: null,
    );
  }

  if (deltaT == null) {
    return ElementCalculationResult(
      isReady: false,
      error: 'Ti ва Tt тўлдирилмаган',
      grossArea: gross,
      netArea: net,
      deltaT: null,
      betaSum: beta,
      orientationBeta: orientationBeta,
      rValue: r,
      nValue: n,
      firstBracket: null,
      secondBracket: null,
      q: null,
    );
  }

  if (beta == null) {
    return ElementCalculationResult(
      isReady: false,
      error: 'Σβ киритилмаса ҳисобланмайди',
      grossArea: gross,
      netArea: net,
      deltaT: deltaT,
      betaSum: null,
      orientationBeta: orientationBeta,
      rValue: r,
      nValue: n,
      firstBracket: null,
      secondBracket: null,
      q: null,
    );
  }

  if (r == null || r <= 0) {
    return ElementCalculationResult(
      isReady: false,
      error: 'R 0 дан катта бўлиши керак',
      grossArea: gross,
      netArea: net,
      deltaT: deltaT,
      betaSum: beta,
      orientationBeta: orientationBeta,
      rValue: r,
      nValue: n,
      firstBracket: null,
      secondBracket: null,
      q: null,
    );
  }

  if (item.kind.usesN && (n == null || n <= 0)) {
    return ElementCalculationResult(
      isReady: false,
      error: 'n киритилмаган',
      grossArea: gross,
      netArea: net,
      deltaT: deltaT,
      betaSum: beta,
      orientationBeta: orientationBeta,
      rValue: r,
      nValue: n,
      firstBracket: null,
      secondBracket: null,
      q: null,
    );
  }

  final double firstBracket = (net * deltaT) / r;
  final double secondBracket = 1.0 + beta + orientationBeta;
  final double q =
      firstBracket * secondBracket * (item.kind.usesN ? n! : 1.0);

  return ElementCalculationResult(
    isReady: true,
    error: null,
    grossArea: gross,
    netArea: net,
    deltaT: deltaT,
    betaSum: beta,
    orientationBeta: orientationBeta,
    rValue: r,
    nValue: item.kind.usesN ? n : null,
    firstBracket: firstBracket,
    secondBracket: secondBracket,
    q: q,
  );
}

  CalcMenuItem? _findCalcItemById(String id) => _itemMap[id];

  String _selectedResultTitle() {
    if (_selectedCalcItemId == 'overall') return 'УМУМИЙ';
    return _itemMap[_selectedCalcItemId]?.title ?? 'НАТИЖА';
  }

  String _activeZoneFromSelected() {
    if (_selectedCalcItemId == 'overall') return 'overall';

    final kind = _itemMap[_selectedCalcItemId]?.kind;
    switch (kind) {
      case CalcItemKind.externalWall:
      case CalcItemKind.column:
      case CalcItemKind.rigel:
        return 'wall';
      case CalcItemKind.externalWindow:
      case CalcItemKind.externalDoor:
        return 'window';
      case CalcItemKind.soilZone:
      case CalcItemKind.floor:
        return 'floor';
      case CalcItemKind.ceiling:
        return 'roof';
      case CalcItemKind.overall:
      case null:
        return 'overall';
    }
  }

  double _savedItemTotal(String id) => _elements[id]?.savedQ ?? 0;

  double _groupTotal(CalcMenuGroup group) {
    double sum = 0;
    for (final item in group.items) {
      sum += _savedItemTotal(item.id);
    }
    return sum;
  }

  double _singleItemTotal(String id) => _savedItemTotal(id);

  String _mainCategoryIdOfSelected() {
    if (_selectedCalcItemId == 'overall') return 'overall';
    if (_selectedCalcItemId == 'floor_single') return 'floor_single';
    if (_selectedCalcItemId == 'ceiling_single') return 'ceiling_single';

    for (final group in _calcGroups) {
      for (final item in group.items) {
        if (item.id == _selectedCalcItemId) {
          return group.id;
        }
      }
    }

    return 'overall';
  }

  OverallSavedSummary _overallSavedSummary() {
    final externalWall = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'external_wall'));
    final externalWindow = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'external_window'));
    final externalDoor = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'external_door'));
    final column = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'column'));
    final rigel = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'rigel'));
    final soil = _groupTotal(_calcGroups.firstWhere((e) => e.id == 'soil_zone'));
    final floor = _singleItemTotal('floor_single');
    final ceiling = _singleItemTotal('ceiling_single');
    final qTos = externalWall +
    externalWindow +
    externalDoor +
    column +
    rigel +
    soil +
    floor +
    ceiling;

final infiltration = _calculateOverallInfiltration();
final overall = qTos + infiltration;

    return OverallSavedSummary(
      externalWall: externalWall,
      externalWindow: externalWindow,
      externalDoor: externalDoor,
      column: column,
      rigel: rigel,
      soil: soil,
      floor: floor,
      ceiling: ceiling,
      qTos: qTos,
      infiltration: infiltration,
      overall: overall,
    );
  }

  ProjectRecord _buildProjectRecord() {
    final records = <String, ElementRecord>{};

    for (final entry in _elements.entries) {
      records[entry.key] = ElementRecord(
        draft: entry.value.toSnapshot(),
        savedQ: entry.value.savedQ,
      );
    }

    final summary = _overallSavedSummary();

    return widget.initialProject.copyWith(
      floorNumber: _floorNumberController.text,
      roomNumber: _roomNumberController.text,
      roomName: _roomNameController.text,
      roomHeight: _roomHeightController.text,
      infiltration: _infiltrationTempController.text,
      elementRecords: records,
      savedAt: DateTime.now(),
      totalSavedQ: summary.overall,
    );
  }

  void _persistProject() {
    widget.onSaveProject(_buildProjectRecord());
  }

  void _selectCalcItem(String itemId) {
    setState(() {
      _selectedCalcItemId = itemId;
    });
  }

  void _selectOverall() {
    setState(() {
      _selectedCalcItemId = 'overall';
    });
  }

  void _calculateSelected() {
    if (_selectedCalcItemId == 'overall') {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Умумий: ${NumberFormatUz.watts(_overallSavedSummary().overall)}',
          ),
        ),
      );
      return;
    }

    final snapshots = _workingSnapshots();
    final result = _calculateFor(_selectedCalcItemId, snapshots);
    final title = _selectedResultTitle();

    if (!result.isReady || result.q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? '$title ҳисобланмади')),
      );
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title = ${NumberFormatUz.watts(result.q!)}'),
      ),
    );
  }

  void _saveSelectedElementToOverall() {
    if (_selectedCalcItemId == 'overall') {
      _persistProject();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Умумий сақланди: ${NumberFormatUz.watts(_overallSavedSummary().overall)}',
          ),
        ),
      );
      return;
    }

    final snapshots = _workingSnapshots();
    final result = _calculateFor(_selectedCalcItemId, snapshots);

    if (!result.isReady || result.q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Сақлаб бўлмади')),
      );
      return;
    }

    setState(() {
      _elements[_selectedCalcItemId]!.savedQ = result.q;
    });

    _persistProject();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_selectedResultTitle()} сақланди. Умумий: ${NumberFormatUz.watts(_overallSavedSummary().overall)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOverallSelected = _selectedCalcItemId == 'overall';
    final activeZone = _activeZoneFromSelected();
    final roomHeight = _parseOrZero(_roomHeightController.text);
    final side = 4.5;
    final currentResult = !isOverallSelected
        ? _calculateFor(_selectedCalcItemId, _workingSnapshots())
        : const ElementCalculationResult.empty();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildScreenTab(),
              const SizedBox(height: 12),
              _buildProjectMetaCard(),
              const SizedBox(height: 12),
              _buildHouseCard(
                length: side,
                width: side,
                height: roomHeight <= 0 ? 3 : roomHeight,
                activeZone: activeZone,
              ),
              const SizedBox(height: 14),
              if (!isOverallSelected) ...[
                _sectionTitle('ЭЛЕМЕНТ ПАРАМЕТРЛАРИ'),
                const SizedBox(height: 10),
                _buildSelectedElementInput(),
                const SizedBox(height: 14),
                _sectionTitle('НАТИЖА'),
                const SizedBox(height: 10),
                _buildSelectedElementResult(currentResult),
                const SizedBox(height: 12),
                _buildFormulaCard(currentResult),
              ] else ...[
  _sectionTitle('УМУМИЙ НАТИЖА'),
  const SizedBox(height: 10),
  _buildOverallInfiltrationSettings(),
  const SizedBox(height: 12),
  _buildOverallCard(),
  const SizedBox(height: 12),
  _buildOverallFormulaCard(),
],
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeName = widget.initialProject.slotTitle;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ТЕПЛОПОТЕРИ КАЛЬКУЛЯТОРИ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeName,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF54F0CA),
              width: 1.4,
            ),
            gradient: const LinearGradient(
              colors: [Color(0xFF15343C), Color(0xFF0A1A20)],
            ),
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF9A8245),
        boxShadow: const [
          BoxShadow(
            color: Color(0x5529E0C2),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'ЛОЙИҲА • ${widget.projectIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectMetaCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ХОНА МАЪЛУМОТЛАРИ',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _floorNumberController,
                  decoration: const InputDecoration(labelText: 'Қават рақами'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _roomNumberController,
                  decoration: const InputDecoration(labelText: 'Хона рақами'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomNameController,
            decoration: const InputDecoration(labelText: 'Хона номи'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomHeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Хона баландлиги, м'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
  child: TextField(
    controller: _infiltrationTempController,
    keyboardType:
        const TextInputType.numberWithOptions(decimal: true),
    decoration: const InputDecoration(
      labelText: 'Инфильтрация учун Ti, °C',
    ),
  ),
),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCard({
    required double length,
    required double width,
    required double height,
    required String activeZone,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        double sceneHeight;
        if (w < 500) {
          sceneHeight = 150;
        } else if (w < 900) {
          sceneHeight = 190;
        } else {
          sceneHeight = 230;
        }

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                height: sceneHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF133844), Color(0xFF0A1E26)],
                  ),
                  border: Border.all(color: const Color(0xFF22515E)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DynamicHouse3DView(
                    length: length,
                    width: width,
                    height: height,
                    activeZone: activeZone,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCalcTreeMenu(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalcTreeMenu() {
    final activeMain = _mainCategoryIdOfSelected();

    final mainItems = <Widget>[
      _buildMainMenuChip(
        title: 'Умумий',
        value: _overallSavedSummary().overall,
        selected: activeMain == 'overall',
        onTap: _selectOverall,
      ),
      ..._calcGroups.map(
        (group) => _buildMainMenuChip(
          title: group.title,
          value: _groupTotal(group),
          selected: activeMain == group.id,
          onTap: () => _selectCalcItem(group.items.first.id),
        ),
      ),
      _buildMainMenuChip(
        title: 'Пол',
        value: _singleItemTotal('floor_single'),
        selected: activeMain == 'floor_single',
        onTap: () => _selectCalcItem('floor_single'),
      ),
      _buildMainMenuChip(
        title: 'Потолок',
        value: _singleItemTotal('ceiling_single'),
        selected: activeMain == 'ceiling_single',
        onTap: () => _selectCalcItem('ceiling_single'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPhone)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: mainItems,
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < mainItems.length; i++) ...[
                      mainItems[i],
                      if (i != mainItems.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            if (activeMain != 'overall' &&
                activeMain != 'floor_single' &&
                activeMain != 'ceiling_single') ...[
              const SizedBox(height: 10),
              _buildSelectedSubMenu(activeMain),
            ],
          ],
        );
      },
    );
  }

  CalcMenuGroup? _groupById(String id) {
    for (final group in _calcGroups) {
      if (group.id == id) return group;
    }
    return null;
  }

  Widget _buildMainMenuChip({
    required String title,
    required double value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    double chipWidth;
    if (screenWidth < 500) {
      chipWidth = (screenWidth - 48) / 2;
    } else if (screenWidth < 900) {
      chipWidth = 170;
    } else {
      chipWidth = 180;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: chipWidth,
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF1ED7BE), Color(0xFF158B7E)],
                )
              : null,
          color: selected ? null : const Color(0xFF0E2128),
          border: Border.all(
            color: selected
                ? const Color(0xFF7BF1DE)
                : const Color(0xFF233A43),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              NumberFormatUz.watts(value),
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSubMenu(String groupId) {
    final group = _groupById(groupId);
    if (group == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 700;
        final phoneWidth = (constraints.maxWidth - 8) / 2;

        final items = group.items.map((item) {
          final selected = _selectedCalcItemId == item.id;
          final total = _savedItemTotal(item.id);

          return GestureDetector(
            onTap: () => _selectCalcItem(item.id),
            child: Container(
              width: isPhone ? phoneWidth.clamp(120.0, 220.0) : 165,
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF1ED7BE), Color(0xFF158B7E)],
                      )
                    : null,
                color: selected ? null : const Color(0xFF10252D),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7BF1DE)
                      : const Color(0xFF233A43),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    NumberFormatUz.watts(total),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();

        if (isPhone) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items,
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedElementInput() {
  final item = _itemMap[_selectedCalcItemId]!;
  final element = _elements[_selectedCalcItemId]!;
  final snapshots = _workingSnapshots();
  final result = _calculateFor(_selectedCalcItemId, snapshots);

  final soilForcedR = soilZoneResistanceById(item.id);
  if (soilForcedR != null && element.rController.text != soilForcedR.toString()) {
    element.rController.text = soilForcedR.toString();
  }

  final double currentAirLayerR = supportsAirLayerResistance(item.kind)
      ? airLayerResistanceValue(
          kind: item.kind,
          thickness: element.airLayerThickness,
          sign: element.airLayerSign,
        )
      : 0.0;

  final double currentBaseR =
      (soilForcedR ?? _parse(element.rController.text) ?? 0.0);

  final double currentTotalR = currentBaseR + currentAirLayerR;

  return Column(
    children: [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: element.heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Баландлиги, H м'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: element.lengthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Узунлиги, L м'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallStat(
                    title: 'Brutto S',
                    value: '${_fmtDouble(result.grossArea)} м²',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallStat(
                    title: 'Ҳисобий S',
                    value: '${_fmtDouble(result.netArea)} м²',
                  ),
                ),
              ],
            ),
            if (item.kind == CalcItemKind.externalWall) ...[
              const SizedBox(height: 10),
              const Text(
                'Ташқи девор юзаси автоматик айирилади: дераза + эшик + колонна + ригел',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ҲАРОРАТЛАР',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: element.indoorTempController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Хона ҳарорати Ti, °C'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: element.outdoorTempController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Ташқи ҳарорат Tt, °C'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _smallStat(
              title: 'ΔT = Ti - Tt',
              value: result.deltaT == null
                  ? '—'
                  : '${_fmtDouble(result.deltaT!)} °C',
            ),
          ],
        ),
      ),

      if (supportsAirLayerResistance(item.kind)) ...[
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ҚЎШИМЧА R — ҲАВО ҚАТЛАМИ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AirLayerThickness>(
                value: element.airLayerThickness,
                dropdownColor: const Color(0xFF0E2128),
                decoration: InputDecoration(
                  labelText: item.kind == CalcItemKind.floor
                      ? 'Пол учун ҳаво қатлами'
                      : 'Девор / Потолок учун ҳаво қатлами',
                ),
                items: AirLayerThickness.values.map((value) {
                  return DropdownMenuItem<AirLayerThickness>(
                    value: value,
                    child: Text(value.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    element.airLayerThickness = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AirLayerSign>(
                value: element.airLayerSign,
                dropdownColor: const Color(0xFF0E2128),
                decoration: const InputDecoration(
                  labelText: 'Ижобий / Салбий',
                ),
                items: AirLayerSign.values.map((value) {
                  return DropdownMenuItem<AirLayerSign>(
                    value: value,
                    child: Text(value.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    element.airLayerSign = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _smallStat(
                      title: 'Қўшимча R',
                      value: _fmtDouble(currentAirLayerR),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallStat(
                      title: 'R умумий',
                      value: _fmtDouble(currentTotalR),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],

      const SizedBox(height: 12),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'КОЭФФИЦИЕНТЛАР',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (item.kind.usesOrientation) ...[
              DropdownButtonFormField<FacingDirection>(
                value: element.direction,
                dropdownColor: const Color(0xFF0E2128),
                items: FacingDirection.values
                    .where((e) => e != FacingDirection.none)
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    element.direction = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Ориентация',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isSubtractedFromWall(item.kind)) ...[
              DropdownButtonFormField<String>(
                value: element.attachedWallId,
                dropdownColor: const Color(0xFF0E2128),
                decoration: const InputDecoration(
                  labelText: 'Қайси деворга тегишли',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'external_wall_1',
                    child: Text('Ташқи девор - 1'),
                  ),
                  DropdownMenuItem(
                    value: 'external_wall_2',
                    child: Text('Ташқи девор - 2'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    element.attachedWallId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: element.betaSumController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Σβ',
                      hintText: 'масалан 0.05',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _smallStat(
                    title: 'βор',
                    value: _fmtDouble(result.orientationBeta),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: element.rController,
                    enabled: item.kind != CalcItemKind.soilZone,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: item.kind == CalcItemKind.soilZone
                          ? 'R (автоматик зона)'
                          : 'Асосий R',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: element.nController,
                    enabled: item.kind.usesN,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: item.kind.usesN ? 'n' : 'n ишламайди',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildSelectedElementResult(ElementCalculationResult result) {
    final saved = _elements[_selectedCalcItemId]!.savedQ;

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 700;

        final left = GlassCard(
          child: Column(
            children: [
              Text(
                _selectedResultTitle(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.q == null ? '—' : NumberFormatUz.integer(result.q!),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Вт'),
              const SizedBox(height: 16),
              _resultLine('Brutto S', '${_fmtDouble(result.grossArea)} м²'),
              _resultLine('Ҳисобий S', '${_fmtDouble(result.netArea)} м²'),
              _resultLine(
                'ΔT',
                result.deltaT == null ? '—' : '${_fmtDouble(result.deltaT!)} °C',
              ),
              _resultLine(
                'Σβ + βор',
                result.secondBracket == null
                    ? '—'
                    : _fmtDouble(result.secondBracket! - 1),
              ),
              _resultLine(
                'Сақланган',
                saved == null ? 'Йўқ' : NumberFormatUz.watts(saved),
              ),
              if (!result.isReady && result.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  result.error!,
                  style: const TextStyle(
                    color: Color(0xFFFF8E8E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );

        final right = GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ФОРМУЛА БЎЙИЧА',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _formulaLine(
                '1-қавс',
                result.firstBracket == null
                    ? '—'
                    : '(S × ΔT / R) = ${_fmtDouble(result.firstBracket!)}',
              ),
              const SizedBox(height: 8),
              _formulaLine(
                '2-қавс',
                result.secondBracket == null
                    ? '—'
                    : '(1 + Σβ + βор) = ${_fmtDouble(result.secondBracket!)}',
              ),
              const SizedBox(height: 8),
              _formulaLine(
                'n',
                result.nValue == null ? 'ишламайди' : _fmtDouble(result.nValue!),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0D2027),
                  border: Border.all(color: const Color(0xFF203B44)),
                ),
                child: Text(
                  result.q == null
                      ? 'Q = —'
                      : 'Q = ${_fmtDouble(result.firstBracket!)} × ${_fmtDouble(result.secondBracket!)}'
                          '${result.nValue == null ? '' : ' × ${_fmtDouble(result.nValue!)}'}'
                          ' = ${NumberFormatUz.watts(result.q!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

        if (vertical) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildFormulaCard(ElementCalculationResult result) {
    final item = _itemMap[_selectedCalcItemId]!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ҲИСОБЛАШ ТУШУНТИРИШИ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.kind.usesN
                ? 'Q = (S × ΔT / R) × (1 + Σβ + βор) × n'
                : 'Q = (S × ΔT / R) × (1 + Σβ + βор)',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'βор: Ғарб ва Жанубий-Шарқ = 0.05, Жануб ва Жанубий-Ғарб = 0, Шимол/Шарқ/Шимолий-Ғарб/Шимолий-Шарқ = 0.1',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          if (item.kind == CalcItemKind.externalWall)
            const Text(
              'Ташқи деворда ҳисобий юза автоматик айирма билан олинади.',
              style: TextStyle(color: Colors.white70),
            ),
          if (item.kind == CalcItemKind.soilZone)
            const Text(
              'Тупроқ тўсиқларида n қўлланмайди.',
              style: TextStyle(color: Colors.white70),
            ),
          if (!result.isReady && result.error != null) ...[
            const SizedBox(height: 8),
            Text(
              'Сабаб: ${result.error}',
              style: const TextStyle(
                color: Color(0xFFFF8E8E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
Widget _buildOverallInfiltrationSettings() {
  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);
  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltration();
  final double qInf = _calculateOverallInfiltration();

  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ИНФИЛЬТРАЦИЯ',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<InfiltrationKOption>(
          value: _selectedInfiltrationK,
          dropdownColor: const Color(0xFF0E2128),
          decoration: const InputDecoration(
            labelText: 'k қўшимча коэффициент',
          ),
          items: InfiltrationKOption.values.map((value) {
            return DropdownMenuItem<InfiltrationKOption>(
              value: value,
              child: Text('${value.title}  •  k=${value.kValue}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedInfiltrationK = value;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _smallStat(
                title: 'Ti → Gi',
                value: '${normalizedTemp}°C → ${_fmtDouble(gi, digits: 3)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStat(
                title: 'ΔT max',
                value: _fmtDouble(maxDt),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _smallStat(
          title: 'Qинф',
          value: NumberFormatUz.watts(qInf),
        ),
      ],
    ),
  );
}
  Widget _buildOverallCard() {
    final summary = _overallSavedSummary();

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 700;

        final left = GlassCard(
          child: Column(
            children: [
              const Text(
                'УМУМИЙ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                NumberFormatUz.integer(summary.overall),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Вт'),
              const SizedBox(height: 16),
              _resultLine('Qтўс', NumberFormatUz.watts(summary.qTos)),
              _resultLine('Инфильтрация', NumberFormatUz.watts(summary.infiltration)),
              _resultLine('Умумий', NumberFormatUz.watts(summary.overall)),
            ],
          ),
        );

        final right = GlassCard(
          child: Column(
            children: [
              _resultLine('Ташқи девор', NumberFormatUz.watts(summary.externalWall)),
              _resultLine('Ташқи дераза', NumberFormatUz.watts(summary.externalWindow)),
              _resultLine('Ташқи эшик', NumberFormatUz.watts(summary.externalDoor)),
              _resultLine('Колонна', NumberFormatUz.watts(summary.column)),
              _resultLine('Ригел', NumberFormatUz.watts(summary.rigel)),
              _resultLine('Тупроқ тўсиқлари', NumberFormatUz.watts(summary.soil)),
              _resultLine('Пол', NumberFormatUz.watts(summary.floor)),
              _resultLine('Потолок', NumberFormatUz.watts(summary.ceiling)),
            ],
          ),
        );

        if (vertical) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildOverallFormulaCard() {
  final s = _overallSavedSummary();

  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);
  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltration();
  final double k = _selectedInfiltrationK.kValue;

  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'УМУМИЙ ФОРМУЛА',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 10),
        const Text(
          'Qумумий = Qтўс + Qинф',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'Qтўс = ${NumberFormatUz.watts(s.qTos)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          'Qинф = 0.28 × 1.005 × (H × Gi) × ΔTmax × k',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'H = ${_roomHeightController.text.isEmpty ? '0' : _roomHeightController.text}, '
          'Gi = ${_fmtDouble(gi, digits: 3)}, '
          'ΔTmax = ${_fmtDouble(maxDt)}, '
          'k = ${_fmtDouble(k, digits: 1)}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'Qумумий = ${NumberFormatUz.watts(s.qTos)} + ${NumberFormatUz.watts(s.infiltration)} = ${NumberFormatUz.watts(s.overall)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
  Widget _buildActionButtons() {
    final bool isOverall = _selectedCalcItemId == 'overall';

    ButtonStyle roundedStyle({
      required Color background,
      required Color foreground,
      Color? borderColor,
    }) {
      return ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        minimumSize: const Size.fromHeight(58),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 1.2,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _calculateSelected,
            icon: const Icon(Icons.calculate_rounded),
            label: const Text(
              'ҲИСОБЛАШ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: roundedStyle(
              background: const Color(0xFF26D9BF),
              foreground: const Color(0xFF032129),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveSelectedElementToOverall,
            icon: const Icon(Icons.save_rounded),
            label: Text(
              isOverall ? 'УМУМИЙНИ САҚЛАШ' : 'ЭЛЕМЕНТНИ САҚЛАШ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: roundedStyle(
              background: const Color(0xFF10252D),
              foreground: Colors.white,
              borderColor: const Color(0xFF2EDCC2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formulaLine(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _smallStat({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2027),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF203B44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }
}

class ProjectsScreen extends StatelessWidget {
  final List<ProjectRecord> projects;
  final int selectedProjectIndex;
  final void Function(int index) onSelectProject;

  const ProjectsScreen({
    super.key,
    required this.projects,
    required this.selectedProjectIndex,
    required this.onSelectProject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ЛОЙИҲАЛАР',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Сақланган ёки янги лойиҳани танланг. Жами: ${projects.length} та слот.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final selected = selectedProjectIndex == index;

                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: InkWell(
                        onTap: () => onSelectProject(index),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1EC6B3)
                                    : const Color(0xFF10252D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: selected
                                        ? const Color(0xFF032129)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.slotTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    project.roomName.isEmpty
                                        ? 'Ҳозирча сақланмаган'
                                        : project.roomName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    project.isSaved
                                        ? 'Q = ${NumberFormatUz.watts(project.totalSavedQ)}'
                                        : 'Маълумот йўқ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selected ? 'Танланган' : 'Очиш',
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF4EF0D1)
                                    : Colors.white54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text(
              'МАЪЛУМОТНОМА',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16),
            GlassCard(
              child: Text(
                'Бу версияда асосийси ҳисоб формуласи тўғриланди:\n'
                'Q = (S × ΔT / R) × (1 + Σβ + βор) × n\n\n'
                'Тупроқ зоналарида n ишламайди.\n'
                'Ташқи девор юзаси автоматик айирма билан ҳисобланади.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text(
              'СОЗЛАМАЛАР',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16),
            GlassCard(
              child: Text(
                'Ҳозирча асосий версия. Кейин экспорт, Excel ва PDF қўшилади.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122730), Color(0xFF0A1B22)],
        ),
        border: Border.all(color: const Color(0xFF1E3943)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DynamicHouse3DView extends StatelessWidget {
  final double length;
  final double width;
  final double height;
  final String activeZone;

  const DynamicHouse3DView({
    super.key,
    required this.length,
    required this.width,
    required this.height,
    this.activeZone = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(
        begin: 0.92,
        end: activeZone.isEmpty ? 0.92 : 1.08,
      ),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: House3DPainter(
              l: length,
              w: width,
              h: height,
              activeZone: activeZone,
              scaleFactor: scale,
            ),
          ),
        );
      },
    );
  }
}

class House3DPainter extends CustomPainter {
  final double l;
  final double w;
  final double h;
  final String activeZone;
  final double scaleFactor;

  House3DPainter({
    required this.l,
    required this.w,
    required this.h,
    required this.activeZone,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final safeL = l <= 0 ? 4.0 : l;
    final safeW = w <= 0 ? 4.0 : w;
    final safeH = h <= 0 ? 3.0 : h;

    double baseScale = (size.width / (safeL + safeW + 2.4)) * scaleFactor;
    baseScale = baseScale.clamp(10.0, 38.0).toDouble();

    Offset center = Offset(
      size.width / 2,
      size.height / 2 + (safeH * baseScale / 2.6),
    );

    if (activeZone == 'window') {
      center = center.translate(-safeL * baseScale * 0.10, 0);
    }
    if (activeZone == 'roof') {
      center = center.translate(0, safeH * baseScale * 0.18);
    }
    if (activeZone == 'floor') {
      center = center.translate(0, -safeH * baseScale * 0.06);
    }

    Offset project(double x, double y, double z) {
      final px = (x - y) * math.cos(math.pi / 6);
      final py = (x + y) * math.sin(math.pi / 6) - z;
      return center + Offset(px * baseScale, py * baseScale);
    }

    void drawFace(List<Offset> points, Color color, bool isActive) {
      final path = Path()..addPolygon(points, true);

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = isActive ? color.withOpacity(0.92) : color.withOpacity(0.42);

      canvas.drawPath(path, fill);
      canvas.drawPath(path, linePaint);

      if (isActive) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withOpacity(0.35);
        canvas.drawPath(path, glow);
      }
    }

    void drawWindow(List<Offset> points, bool isActive) {
      final path = Path()..addPolygon(points, true);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
            colors: [Color(0xAA9BE7FF), Color(0x663AA5C8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(path.getBounds()),
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.2 : 1.2
          ..color = isActive ? const Color(0xFFBDF5FF) : Colors.white54,
      );
    }

    final floorFace = [
      project(0.0, 0.0, 0.0),
      project(safeL, 0.0, 0.0),
      project(safeL, safeW, 0.0),
      project(0.0, safeW, 0.0),
    ];

    final frontWallFace = [
      project(0.0, 0.0, 0.0),
      project(safeL, 0.0, 0.0),
      project(safeL, 0.0, safeH),
      project(0.0, 0.0, safeH),
    ];

    final backWallFace = [
      project(0.0, safeW, 0.0),
      project(safeL, safeW, 0.0),
      project(safeL, safeW, safeH),
      project(0.0, safeW, safeH),
    ];

    final roofFace = [
      project(0.0, 0.0, safeH),
      project(safeL, 0.0, safeH),
      project(safeL, safeW, safeH),
      project(0.0, safeW, safeH),
    ];

    drawFace(floorFace, const Color(0xFF506A77), activeZone == 'floor');
    drawFace(backWallFace, const Color(0xFF1A8C85), activeZone == 'wall');
    drawFace(frontWallFace, const Color(0xFF1FA79B), activeZone == 'wall');
    drawFace(roofFace, const Color(0xFF818996), activeZone == 'roof');

    final winW = safeL * 0.36;
    final winH = safeH * 0.42;
    final winLeft = safeL / 2 - winW / 2;
    final winBottom = safeH * 0.26;

    drawWindow(
      [
        project(winLeft, 0.0, winBottom),
        project(winLeft + winW, 0.0, winBottom),
        project(winLeft + winW, 0.0, winBottom + winH),
        project(winLeft, 0.0, winBottom + winH),
      ],
      activeZone == 'window',
    );
  }

  @override
  bool shouldRepaint(covariant House3DPainter oldDelegate) {
    return oldDelegate.l != l ||
        oldDelegate.w != w ||
        oldDelegate.h != h ||
        oldDelegate.activeZone != activeZone ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}

class NumberFormatUz {
  static String integer(double value) {
    final rounded = value.round();
    final raw = rounded.toString();
    final result = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final indexFromEnd = raw.length - i;
      result.write(raw[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        result.write(' ');
      }
    }

    return result.toString();
  }

  static String watts(double value) => '${integer(value)} Вт';
}