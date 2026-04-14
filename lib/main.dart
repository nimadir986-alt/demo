import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reference_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HeatLossApp());
}

class SantexColors {
  static const Color bg = Color(0xFF071018);
  static const Color bg2 = Color(0xFF0A1620);
  static const Color card = Color(0xFF0C1721);
  static const Color card2 = Color(0xFF101D29);
  static const Color border = Color(0xFF213545);
  static const Color borderSoft = Color(0xFF1A2A36);

  static const Color inputBg = Color(0xFF0C1720);
  static const Color inputBorder = Color(0xFF304250);
  static const Color inputFocus = Color(0xFF4A86D9);

  static const Color keypad = Color(0xFF2B2B35);
  static const Color keypadBorder = Color(0xFF505564);

  static const Color blueBtn = Color(0xFF245FBA);
  static const Color blueBtn2 = Color(0xFF2F73DB);
  static const Color redBtn = Color(0xFF4A1C24);
  static const Color redBorder = Color(0xFF8B3A49);
  static const Color greenPanel = Color(0xFF0E2B28);
  static const Color greenText = Color(0xFF46E2A8);

  static const Color text = Color(0xFFE7EDF2);
  static const Color dimText = Color(0xFF98A8B6);
  static const Color label = Color(0xFF6F8798);
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
  scaffoldBackgroundColor: SantexColors.bg,
  colorScheme: const ColorScheme.dark(
    primary: SantexColors.blueBtn2,
    secondary: SantexColors.greenText,
    surface: SantexColors.card,
    error: Color(0xFFFF5B5B),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: SantexColors.text),
    bodyLarge: TextStyle(color: SantexColors.text),
    titleMedium: TextStyle(color: SantexColors.text),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SantexColors.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    labelStyle: const TextStyle(
      color: SantexColors.label,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    hintStyle: const TextStyle(color: Colors.white30),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SantexColors.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SantexColors.inputBorder, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: SantexColors.inputFocus, width: 1.5),
    ),
  ),
),     home: const MainNavigationPage(),
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

enum WallExtraOption {
  none,
  twoSidesOpen,
  threeSidesOpen,
}

extension WallExtraOptionX on WallExtraOption {
  String get title {
    switch (this) {
      case WallExtraOption.none:
        return 'Йўқ';
      case WallExtraOption.twoSidesOpen:
        return 'Ташқи девор икки томондан очиқ';
      case WallExtraOption.threeSidesOpen:
        return 'Ташқи девор уч томондан очиқ';
    }
  }

  double get value {
    switch (this) {
      case WallExtraOption.none:
        return 0.0;
      case WallExtraOption.twoSidesOpen:
        return 0.05;
      case WallExtraOption.threeSidesOpen:
        return 0.10;
    }
  }
}

enum DoorExtraOption {
  none,
  tripleDoorWithTambour,
  doubleDoorWithTambour,
  doubleDoorNoTambour,
  singleDoorNoTambour,
  noCurtain,
  outsideTambour,
}

extension DoorExtraOptionX on DoorExtraOption {
  String get title {
    switch (this) {
      case DoorExtraOption.none:
        return 'Йўқ';
      case DoorExtraOption.tripleDoorWithTambour:
        return '3 талик эшик 2 та тамбур билан';
      case DoorExtraOption.doubleDoorWithTambour:
        return '2 талик эшик тамбур билан';
      case DoorExtraOption.doubleDoorNoTambour:
        return '2 талик эшик тамбурсиз';
      case DoorExtraOption.singleDoorNoTambour:
        return '1 талик эшик тамбурсиз';
      case DoorExtraOption.noCurtain:
        return 'Тамбур ва ҳаво-иссиқлик пардаси йўқ';
      case DoorExtraOption.outsideTambour:
        return 'Дарвоза олдида тамбур бўлса';
    }
  }

  double get value {
    switch (this) {
      case DoorExtraOption.none:
        return 0.0;
      case DoorExtraOption.tripleDoorWithTambour:
        return 0.20;
      case DoorExtraOption.doubleDoorWithTambour:
        return 0.27;
      case DoorExtraOption.doubleDoorNoTambour:
        return 0.34;
      case DoorExtraOption.singleDoorNoTambour:
        return 0.22;
      case DoorExtraOption.noCurtain:
        return 0.05;
      case DoorExtraOption.outsideTambour:
        return 0.10;
    }
  }
}

class OutdoorTempOption {
  final String city;
  final double temp;

  const OutdoorTempOption(this.city, this.temp);
}

const List<OutdoorTempOption> kOutdoorTempOptions = [
  OutdoorTempOption('Қарақалпақия', -30),
  OutdoorTempOption('Мўйноқ', -23),
  OutdoorTempOption('Нукус', -23),
  OutdoorTempOption('Чимбой', -23),
  OutdoorTempOption('Андижон', -16),
  OutdoorTempOption('Хонобод', -17),
  OutdoorTempOption('Бухоро', -15),
  OutdoorTempOption('Ғиждувон', -16),
  OutdoorTempOption('Қоракўл', -15),
  OutdoorTempOption('Ғаллаорол', -22),
  OutdoorTempOption('Жиззах', -19),
  OutdoorTempOption('Дўстлик', -18),
  OutdoorTempOption('Ғузор', -13),
  OutdoorTempOption('Қарши', -17),
  OutdoorTempOption('Минчуқур', -16),
  OutdoorTempOption('Муборак', -16),
  OutdoorTempOption('Шахрисабз', -14),
  OutdoorTempOption('Зарафшон', -14),
  OutdoorTempOption('Навоий', -16),
  OutdoorTempOption('Нурота', -19),
  OutdoorTempOption('Учқудуқ', -19),
  OutdoorTempOption('Косонсой', -14),
  OutdoorTempOption('Наманган', -17),
  OutdoorTempOption('Поп', -14),
  OutdoorTempOption('Каттақўрғон', -16),
  OutdoorTempOption('Қўшработ', -19),
  OutdoorTempOption('Самарқанд', -14),
  OutdoorTempOption('Денов', -11),
  OutdoorTempOption('Термиз', -12),
  OutdoorTempOption('Шеробод', -10),
  OutdoorTempOption('Гулистон', -22),
  OutdoorTempOption('Сирдарё', -20),
  OutdoorTempOption('Янгиер', -19),
  OutdoorTempOption('Олмалиқ', -14),
  OutdoorTempOption('Ангрен', -14),
  OutdoorTempOption('Бекобод', -18),
  OutdoorTempOption('Ойгаинг', -22),
  OutdoorTempOption('Ташкент', -16),
  OutdoorTempOption('Чорвоқ', -15),
  OutdoorTempOption('Чирчиқ', -16),
  OutdoorTempOption('Қўқон', -14),
  OutdoorTempOption('Фарғона', -15),
  OutdoorTempOption('Шохимардон', -15),
  OutdoorTempOption('Урганч', -21),
  OutdoorTempOption('Хива', -20),
];

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


const Object _noValue = Object();

class ElementSnapshot {
  final String height;
  final String length;
  final String indoorTemp;
  final String outdoorTemp;
  final String? selectedOutdoorCity;
  final String betaSum;
  final String rValue;
  final String nValue;
  final FacingDirection direction;
  final String attachedWallId;
  final AirLayerThickness airLayerThickness;
  final AirLayerSign airLayerSign;
  final WallExtraOption wallExtraOption;
final DoorExtraOption doorExtraOption;


  const ElementSnapshot({
  required this.height,
  required this.length,
  required this.indoorTemp,
  required this.outdoorTemp,
  required this.selectedOutdoorCity,
  required this.betaSum,
  required this.rValue,
  required this.nValue,
  required this.direction,
  required this.attachedWallId,
  required this.airLayerThickness,
  required this.airLayerSign,
  required this.wallExtraOption,
  required this.doorExtraOption,
});

  factory ElementSnapshot.defaults(CalcMenuItem item) {
    final String n = item.kind.usesN ? '1' : '';
    final soilR = soilZoneResistanceById(item.id);
    final String r = soilR != null ? soilR.toString() : '1';

  return ElementSnapshot(
  height: '',
  length: '',
  indoorTemp: '20',
  outdoorTemp: '-16',
  selectedOutdoorCity: 'Ташкент',
  betaSum: '0',
  rValue: r,
  nValue: n,
  direction: item.kind.usesOrientation
      ? FacingDirection.south
      : FacingDirection.none,
  attachedWallId: 'external_wall_1',
  airLayerThickness: AirLayerThickness.none,
  airLayerSign: AirLayerSign.positive,
  wallExtraOption: WallExtraOption.none,
  doorExtraOption: DoorExtraOption.none,
);
  }

 ElementSnapshot copyWith({
  String? height,
  String? length,
  String? indoorTemp,
  String? outdoorTemp,
  Object? selectedOutdoorCity = _noValue,
  String? betaSum,
  String? rValue,
  String? nValue,
  FacingDirection? direction,
  String? attachedWallId,
  AirLayerThickness? airLayerThickness,
  AirLayerSign? airLayerSign,
  WallExtraOption? wallExtraOption,
  DoorExtraOption? doorExtraOption,
}) {
  return ElementSnapshot(
    height: height ?? this.height,
    length: length ?? this.length,
    indoorTemp: indoorTemp ?? this.indoorTemp,
    outdoorTemp: outdoorTemp ?? this.outdoorTemp,
    selectedOutdoorCity: selectedOutdoorCity == _noValue
        ? this.selectedOutdoorCity
        : selectedOutdoorCity as String?,
    betaSum: betaSum ?? this.betaSum,
    rValue: rValue ?? this.rValue,
    nValue: nValue ?? this.nValue,
    direction: direction ?? this.direction,
    attachedWallId: attachedWallId ?? this.attachedWallId,
    airLayerThickness: airLayerThickness ?? this.airLayerThickness,
    airLayerSign: airLayerSign ?? this.airLayerSign,
    wallExtraOption: wallExtraOption ?? this.wallExtraOption,
    doorExtraOption: doorExtraOption ?? this.doorExtraOption,
  );
}

 Map<String, dynamic> toJson() {
  return {
    'height': height,
    'length': length,
    'indoorTemp': indoorTemp,
    'outdoorTemp': outdoorTemp,
    'selectedOutdoorCity': selectedOutdoorCity,
    'betaSum': betaSum,
    'rValue': rValue,
    'nValue': nValue,
    'direction': direction.name,
    'attachedWallId': attachedWallId,
    'airLayerThickness': airLayerThickness.name,
    'airLayerSign': airLayerSign.name,
    'wallExtraOption': wallExtraOption.name,
    'doorExtraOption': doorExtraOption.name,
  };
}

 factory ElementSnapshot.fromJson(Map<String, dynamic> json) {
  return ElementSnapshot(
    height: (json['height'] ?? '').toString(),
    length: (json['length'] ?? '').toString(),
    indoorTemp: (json['indoorTemp'] ?? '20').toString(),
    outdoorTemp: (json['outdoorTemp'] ?? '-15').toString(),
    selectedOutdoorCity: json['selectedOutdoorCity']?.toString(),
    betaSum: (json['betaSum'] ?? '').toString(),
    rValue: (json['rValue'] ?? '1').toString(),
    nValue: (json['nValue'] ?? '').toString(),
    direction: FacingDirection.values.firstWhere(
      (e) => e.name == json['direction'],
      orElse: () => FacingDirection.none,
    ),
    attachedWallId: (json['attachedWallId'] ?? 'external_wall_1').toString(),
    airLayerThickness: AirLayerThickness.values.firstWhere(
      (e) => e.name == json['airLayerThickness'],
      orElse: () => AirLayerThickness.none,
    ),
    airLayerSign: AirLayerSign.values.firstWhere(
      (e) => e.name == json['airLayerSign'],
      orElse: () => AirLayerSign.positive,
    ),
    wallExtraOption: WallExtraOption.values.firstWhere(
      (e) => e.name == json['wallExtraOption'],
      orElse: () => WallExtraOption.none,
    ),
    doorExtraOption: DoorExtraOption.values.firstWhere(
      (e) => e.name == json['doorExtraOption'],
      orElse: () => DoorExtraOption.none,
    ),
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

  Map<String, dynamic> toJson() {
    return {
      'draft': draft.toJson(),
      'savedQ': savedQ,
    };
  }

  factory ElementRecord.fromJson(Map<String, dynamic> json) {
    return ElementRecord(
      draft: ElementSnapshot.fromJson(
        Map<String, dynamic>.from(json['draft'] as Map),
      ),
      savedQ: (json['savedQ'] as num?)?.toDouble(),
    );
  }
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
  String? selectedOutdoorCity;
  double? savedQ;
  WallExtraOption wallExtraOption;
DoorExtraOption doorExtraOption;

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
      airLayerSign = snapshot.airLayerSign,
      wallExtraOption = snapshot.wallExtraOption,
doorExtraOption = snapshot.doorExtraOption,
      selectedOutdoorCity = snapshot.selectedOutdoorCity;

  ElementSnapshot toSnapshot() {
  return ElementSnapshot(
    height: heightController.text,
    length: lengthController.text,
    indoorTemp: indoorTempController.text,
    outdoorTemp: outdoorTempController.text,
    selectedOutdoorCity: selectedOutdoorCity,
    betaSum: betaSumController.text,
    rValue: rController.text,
    nValue: nController.text,
    direction: direction,
    attachedWallId: attachedWallId,
    airLayerThickness: airLayerThickness,
    airLayerSign: airLayerSign,
    wallExtraOption: wallExtraOption,
    doorExtraOption: doorExtraOption,
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

class RoomRecord {
  final String roomTitle;
  final String floorNumber;
  final String roomNumber;
  final String roomName;
  final String roomHeight;
  final String roomArea;
  final String infiltration;
  final Map<String, ElementRecord> elementRecords;
  final DateTime? savedAt;
  final double totalSavedQ;

  const RoomRecord({
    required this.roomTitle,
    this.floorNumber = '',
    this.roomNumber = '',
    this.roomName = '',
    this.roomHeight = '',
    this.roomArea = '',
    this.infiltration = '20',
    this.elementRecords = const {},
    this.savedAt,
    this.totalSavedQ = 0,
  });

  bool get isSaved =>
      savedAt != null || elementRecords.values.any((e) => e.savedQ != null);

  String get displayTitle {
    final n = roomName.trim();
    return n.isNotEmpty ? n : roomTitle;
  }

  RoomRecord copyWith({
    String? floorNumber,
    String? roomNumber,
    String? roomName,
    String? roomHeight,
    String? roomArea,
    String? infiltration,
    Map<String, ElementRecord>? elementRecords,
    DateTime? savedAt,
    double? totalSavedQ,
  }) {
    return RoomRecord(
      roomTitle: roomTitle,
      floorNumber: floorNumber ?? this.floorNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      roomName: roomName ?? this.roomName,
      roomHeight: roomHeight ?? this.roomHeight,
      roomArea: roomArea ?? this.roomArea,
      infiltration: infiltration ?? this.infiltration,
      elementRecords: elementRecords ?? this.elementRecords,
      savedAt: savedAt ?? this.savedAt,
      totalSavedQ: totalSavedQ ?? this.totalSavedQ,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomTitle': roomTitle,
      'floorNumber': floorNumber,
      'roomNumber': roomNumber,
      'roomName': roomName,
      'roomHeight': roomHeight,
      'roomArea': roomArea,
      'infiltration': infiltration,
      'elementRecords': elementRecords.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'savedAt': savedAt?.toIso8601String(),
      'totalSavedQ': totalSavedQ,
    };
  }

  factory RoomRecord.fromJson(Map<String, dynamic> json) {
    final rawMap = (json['elementRecords'] as Map?) ?? const {};
    return RoomRecord(
      roomTitle: (json['roomTitle'] ?? 'Хона').toString(),
      floorNumber: (json['floorNumber'] ?? '').toString(),
      roomNumber: (json['roomNumber'] ?? '').toString(),
      roomName: (json['roomName'] ?? '').toString(),
      roomHeight: (json['roomHeight'] ?? '').toString(),
      roomArea: (json['roomArea'] ?? '').toString(),
      infiltration: (json['infiltration'] ?? '20').toString(),
      elementRecords: rawMap.map<String, ElementRecord>(
        (key, value) => MapEntry(
          key.toString(),
          ElementRecord.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'].toString())
          : null,
      totalSavedQ: (json['totalSavedQ'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProjectRecord {
  final String slotTitle;
  final List<RoomRecord> rooms;
  final DateTime? savedAt;
  final double totalSavedQ;

  const ProjectRecord({
    required this.slotTitle,
    this.rooms = const [],
    this.savedAt,
    this.totalSavedQ = 0,
  });

  bool get isSaved =>
      savedAt != null ||
      rooms.any((room) => room.isSaved || room.totalSavedQ > 0);

  ProjectRecord copyWith({
    List<RoomRecord>? rooms,
    DateTime? savedAt,
    double? totalSavedQ,
  }) {
    return ProjectRecord(
      slotTitle: slotTitle,
      rooms: rooms ?? this.rooms,
      savedAt: savedAt ?? this.savedAt,
      totalSavedQ: totalSavedQ ?? this.totalSavedQ,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slotTitle': slotTitle,
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'savedAt': savedAt?.toIso8601String(),
      'totalSavedQ': totalSavedQ,
    };
  }

  factory ProjectRecord.fromJson(Map<String, dynamic> json) {
    final rawRooms = (json['rooms'] as List?) ?? const [];
    return ProjectRecord(
      slotTitle: (json['slotTitle'] ?? 'Лойиҳа').toString(),
      rooms: rawRooms
          .map((e) => RoomRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      savedAt: json['savedAt'] != null
          ? DateTime.tryParse(json['savedAt'].toString())
          : null,
      totalSavedQ: (json['totalSavedQ'] as num?)?.toDouble() ?? 0,
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
  static const String _projectsStorageKey = 'heat_loss_projects_v1';

  int _currentIndex = 1;
  int _selectedProjectIndex = 0;
  int _selectedRoomIndex = 0;
  bool _isLoading = true;
  int _calculatorViewIndex = 0; // 0 = hub, 1 = teplopoterya

  late List<ProjectRecord> _projects;

  @override
  void initState() {
    super.initState();
    _projects = _buildDefaultProjects();
    _loadProjectsFromStorage();
  }

  List<ProjectRecord> _buildDefaultProjects() {
    return List.generate(
      50,
      (projectIndex) => ProjectRecord(
        slotTitle: 'Лойиҳа ${projectIndex + 1}',
        rooms: List.generate(
          50,
          (roomIndex) => RoomRecord(
            roomTitle: 'Хона ${roomIndex + 1}',
          ),
        ),
      ),
    );
  }

  Future<void> _loadProjectsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsStorageKey);

    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List;
      final loaded = decoded
          .map((e) => ProjectRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (!mounted) return;
      setState(() {
        _projects = loaded;
        _selectedProjectIndex =
            _selectedProjectIndex.clamp(0, _projects.length - 1);
        _selectedRoomIndex = _selectedRoomIndex.clamp(
          0,
          _projects[_selectedProjectIndex].rooms.length - 1,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _projects = _buildDefaultProjects();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProjectsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_projects.map((e) => e.toJson()).toList());
    await prefs.setString(_projectsStorageKey, raw);
  }

  ProjectRecord get _activeProject => _projects[_selectedProjectIndex];
  RoomRecord get _activeRoom => _activeProject.rooms[_selectedRoomIndex];

  double _projectTotal(ProjectRecord project) {
    double sum = 0;
    for (final room in project.rooms) {
      sum += room.totalSavedQ;
    }
    return sum;
  }

  void _selectProject(int index) {
  setState(() {
    _selectedProjectIndex = index;
    _selectedRoomIndex = 0;
  });
}

  void _selectRoom(int index) {
  setState(() {
    _selectedRoomIndex = index;
    _currentIndex = 1;
    _calculatorViewIndex = 1;
  });
}

    void _saveRoom(RoomRecord updatedRoom) {
    setState(() {
      final currentProject = _projects[_selectedProjectIndex];
      final updatedRooms = List<RoomRecord>.from(currentProject.rooms);
      updatedRooms[_selectedRoomIndex] = updatedRoom;

      double total = 0;
      for (final room in updatedRooms) {
        total += room.totalSavedQ;
      }

      _projects[_selectedProjectIndex] = currentProject.copyWith(
        rooms: updatedRooms,
        savedAt: DateTime.now(),
        totalSavedQ: total,
      );
    });

    _saveProjectsToStorage();
  }

    void _saveRoomDraft(RoomRecord updatedRoom) {
    setState(() {
      final currentProject = _projects[_selectedProjectIndex];
      final updatedRooms = List<RoomRecord>.from(currentProject.rooms);
      updatedRooms[_selectedRoomIndex] = updatedRoom;

      double total = 0;
      for (final room in updatedRooms) {
        total += room.totalSavedQ;
      }

      _projects[_selectedProjectIndex] = currentProject.copyWith(
        rooms: updatedRooms,
        totalSavedQ: total,
      );
    });

    _saveProjectsToStorage();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ProjectsScreen(
        projects: _projects,
        selectedProjectIndex: _selectedProjectIndex,
        selectedRoomIndex: _selectedRoomIndex,
        onSelectProject: _selectProject,
        onSelectRoom: _selectRoom,
      ),
      _calculatorViewIndex == 0
    ? CalculatorsHubScreen(
        onOpenHeatLoss: () {
          setState(() {
            _calculatorViewIndex = 1;
          });
        },
      )
    : CalculatorScreen(
        key: ValueKey(
          '${_selectedProjectIndex}_${_selectedRoomIndex}_${_activeRoom.savedAt?.millisecondsSinceEpoch ?? 0}',
        ),
        projectIndex: _selectedProjectIndex,
        roomIndex: _selectedRoomIndex,
        projectTitle: _activeProject.slotTitle,
        initialRoom: _activeRoom,
        projectRooms: _activeProject.rooms,
        projectTotalQ: _projectTotal(_activeProject),
        onSaveRoom: _saveRoom,
        onDraftChanged: _saveRoomDraft,
        onSelectRoom: _selectRoom,
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
              onTap: () {
  setState(() {
    _currentIndex = index;
    if (index == 1) {
      _calculatorViewIndex = 0;
    }
  });
},
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
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
  final int roomIndex;
  final String projectTitle;
  final RoomRecord initialRoom;
  final List<RoomRecord> projectRooms;
  final double projectTotalQ;
  final ValueChanged<RoomRecord> onSaveRoom;
  final ValueChanged<RoomRecord> onDraftChanged;
  final ValueChanged<int> onSelectRoom;

  const CalculatorScreen({
  super.key,
  required this.projectIndex,
  required this.roomIndex,
  required this.projectTitle,
  required this.initialRoom,
  required this.projectRooms,
  required this.projectTotalQ,
  required this.onSaveRoom,
  required this.onDraftChanged,
  required this.onSelectRoom,
});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}


class _CalculatorScreenState extends State<CalculatorScreen> {
final TextEditingController _floorNumberController = TextEditingController();
final TextEditingController _roomNumberController = TextEditingController();
final TextEditingController _roomNameController = TextEditingController();
final TextEditingController _roomHeightController = TextEditingController();
final TextEditingController _roomAreaController = TextEditingController();

final TextEditingController _infiltrationTempController =
    TextEditingController(text: '20');

InfiltrationKOption _selectedInfiltrationK =
    InfiltrationKOption.tightPanels;

  String _selectedCalcItemId = 'overall';
  String? _activeInputKey;

    Map<String, ElementSnapshot>? _snapshotCache;
  bool _snapshotDirty = true;
  bool _showRoomPicker = false;
  Timer? _draftSaveDebounce;

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

   _loadRoom(widget.initialRoom);

    _floorNumberController.addListener(_refresh);
_roomNumberController.addListener(_refresh);
_roomNameController.addListener(_refresh);
_roomHeightController.addListener(_refresh);
_roomAreaController.addListener(_refresh);
_infiltrationTempController.addListener(_refresh);
  }

  void _refresh() {
  _snapshotDirty = true;

  _draftSaveDebounce?.cancel();
  _draftSaveDebounce = Timer(const Duration(milliseconds: 500), () {
    widget.onDraftChanged(_buildDraftRoomRecord());
  });

  if (mounted) setState(() {});
}

void _openRoomSelector() {
  setState(() {
    _showRoomPicker = !_showRoomPicker;
  });
}

void _selectRoomFromInlineList(int index) {
  widget.onSaveRoom(_buildRoomRecord());

  setState(() {
    _showRoomPicker = false;
  });

  widget.onSelectRoom(index);
}

void _loadRoom(RoomRecord room) {
  _floorNumberController.text = room.floorNumber;
  _roomNumberController.text = room.roomNumber;
  _roomNameController.text = room.roomName;
  _roomHeightController.text = room.roomHeight;
  _roomAreaController.text = room.roomArea;
  _infiltrationTempController.text = room.infiltration;

  _elements = {};
  _itemMap.forEach((id, item) {
    final record = room.elementRecords[id];
    final snapshot = record?.draft ?? ElementSnapshot.defaults(item);

    final state = ElementState(
      item: item,
      snapshot: snapshot,
      savedQ: record?.savedQ,
    );
    state.bind(_refresh);
    _elements[id] = state;
  });

  _snapshotDirty = true;
}

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    _floorNumberController.dispose();
    _roomNumberController.dispose();
    _roomNameController.dispose();
    _roomHeightController.dispose();
    _infiltrationTempController.dispose();
    _roomAreaController.dispose();

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

  InputDecoration _editableDecoration(
  String label, {
  String? hintText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFF0D2027),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF203B44)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2C4E59)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Color(0xFF4EF0D1),
        width: 1.4,
      ),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
    hintStyle: const TextStyle(color: Colors.white38),
  );
}

InputDecoration _readonlyDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFF16242A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2E3E45)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF3A4A50)),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF4A5A60)),
    ),
    labelStyle: const TextStyle(
      color: Colors.white60,
      fontWeight: FontWeight.w600,
    ),
  );
}

  String _fmtDouble(double value, {int digits = 2}) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(digits);
}

double _maxPositiveDeltaTForInfiltrationFromSnapshots(
  Map<String, ElementSnapshot> snapshots,
) {
  double maxDt = 0.0;

  for (final snapshot in snapshots.values) {
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

double _calculateOverallInfiltrationFromSnapshots(
  Map<String, ElementSnapshot> snapshots,
) {
  final double height = _parseOrZero(_roomHeightController.text);
  final double area = _parseOrZero(_roomAreaController.text);
  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);

  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltrationFromSnapshots(snapshots);
  final double k = _selectedInfiltrationK.kValue;

  if (height <= 0 || area <= 0 || maxDt <= 0) return 0.0;

  return 0.28 * 1.005 * ((height * area) * gi) * maxDt * k;
}

Map<String, ElementSnapshot> _workingSnapshots() {
  if (!_snapshotDirty && _snapshotCache != null) {
    return _snapshotCache!;
  }

  _snapshotCache = {
    for (final entry in _elements.entries)
      entry.key: entry.value.toSnapshot(),
  };

  _snapshotDirty = false;
  return _snapshotCache!;
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
  final double beta = _parse(snapshot.betaSum) ?? 0.0;
final double n = _parse(snapshot.nValue) ?? 1.0;

  final double? baseR = _parse(snapshot.rValue);

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

  final double wallExtraBeta =
    item.kind == CalcItemKind.externalWall
        ? snapshot.wallExtraOption.value
        : 0.0;

final double doorExtraBeta =
    item.kind == CalcItemKind.externalDoor
        ? snapshot.doorExtraOption.value
        : 0.0;

final double extraBeta = wallExtraBeta + doorExtraBeta;

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

  final double firstBracket = (net * deltaT) / r;
  final double secondBracket = 1.0 + beta + orientationBeta + extraBeta;
final double q =
    firstBracket * secondBracket * (item.kind.usesN ? n : 1.0);

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

  OverallSavedSummary _overallSavedSummaryFromSnapshots(
  Map<String, ElementSnapshot> snapshots,
) {
  double externalWall = 0;
  double externalWindow = 0;
  double externalDoor = 0;
  double column = 0;
  double rigel = 0;
  double soil = 0;
  double floor = 0;
  double ceiling = 0;

  for (final entry in _elements.entries) {
    final q = entry.value.savedQ ?? 0;
    final kind = entry.value.item.kind;

    switch (kind) {
      case CalcItemKind.externalWall:
        externalWall += q;
        break;
      case CalcItemKind.externalWindow:
        externalWindow += q;
        break;
      case CalcItemKind.externalDoor:
        externalDoor += q;
        break;
      case CalcItemKind.column:
        column += q;
        break;
      case CalcItemKind.rigel:
        rigel += q;
        break;
      case CalcItemKind.soilZone:
        soil += q;
        break;
      case CalcItemKind.floor:
        floor += q;
        break;
      case CalcItemKind.ceiling:
        ceiling += q;
        break;
      case CalcItemKind.overall:
        break;
    }
  }

  final qTos = externalWall +
      externalWindow +
      externalDoor +
      column +
      rigel +
      soil +
      floor +
      ceiling;

  final infiltration = _calculateOverallInfiltrationFromSnapshots(snapshots);
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

RoomRecord _buildDraftRoomRecord() {
  final records = <String, ElementRecord>{};

  for (final entry in _elements.entries) {
    records[entry.key] = ElementRecord(
      draft: entry.value.toSnapshot(),
      savedQ: entry.value.savedQ,
    );
  }

  final snapshots = _workingSnapshots();
  final summary = _overallSavedSummaryFromSnapshots(snapshots);

  return widget.initialRoom.copyWith(
    floorNumber: _floorNumberController.text,
    roomNumber: _roomNumberController.text,
    roomName: _roomNameController.text,
    roomHeight: _roomHeightController.text,
    roomArea: _roomAreaController.text,
    infiltration: _infiltrationTempController.text,
    elementRecords: records,
    totalSavedQ: summary.overall,
  );
}

RoomRecord _buildRoomRecord() {
  final records = <String, ElementRecord>{};

  for (final entry in _elements.entries) {
    records[entry.key] = ElementRecord(
      draft: entry.value.toSnapshot(),
      savedQ: entry.value.savedQ,
    );
  }

  final snapshots = _workingSnapshots();
  final summary = _overallSavedSummaryFromSnapshots(snapshots);

  return widget.initialRoom.copyWith(
    floorNumber: _floorNumberController.text,
    roomNumber: _roomNumberController.text,
    roomName: _roomNameController.text,
    roomHeight: _roomHeightController.text,
    roomArea: _roomAreaController.text,
    infiltration: _infiltrationTempController.text,
    elementRecords: records,
    savedAt: DateTime.now(),
    totalSavedQ: summary.overall,
  );
}

  

  void _persistProject() {
  widget.onSaveRoom(_buildRoomRecord());
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
  final snapshots = _workingSnapshots();

  if (_selectedCalcItemId == 'overall') {
    final summary = _overallSavedSummaryFromSnapshots(snapshots);

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Умумий: ${NumberFormatUz.watts(summary.overall)}',
        ),
      ),
    );
    return;
  }

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
  final snapshots = _workingSnapshots();

  if (_selectedCalcItemId == 'overall') {
    _persistProject();
    final summary = _overallSavedSummaryFromSnapshots(snapshots);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Умумий сақланди: ${NumberFormatUz.watts(summary.overall)}',
        ),
      ),
    );
    return;
  }

  final result = _calculateFor(_selectedCalcItemId, snapshots);

  if (!result.isReady || result.q == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.error ?? 'Сақлаб бўлмади')),
    );
    return;
  }

  setState(() {
    _elements[_selectedCalcItemId]!.savedQ = result.q;
    _snapshotDirty = true;
  });

  _persistProject();
  final updatedSummary = _overallSavedSummaryFromSnapshots(_workingSnapshots());

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '${_selectedResultTitle()} сақланди. Умумий: ${NumberFormatUz.watts(updatedSummary.overall)}',
      ),
    ),
  );
}



  @override
Widget build(BuildContext context) {
  final isOverallSelected = _selectedCalcItemId == 'overall';
  final snapshots = _workingSnapshots();
  final overallSummary = _overallSavedSummaryFromSnapshots(snapshots);

  final currentResult = !isOverallSelected
      ? _calculateFor(_selectedCalcItemId, snapshots)
      : const ElementCalculationResult.empty();

  return Scaffold(
    backgroundColor: SantexColors.bg,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildCompactTopTabs(),
            const SizedBox(height: 10),
            _buildCompactInputPanel(
              snapshots: snapshots,
              result: currentResult,
              overallSummary: overallSummary,
            ),
            const SizedBox(height: 10),
            _buildSantexKeypad(
              onDigit: _handleKey,
            ),
            const SizedBox(height: 10),
            _buildCompactAdvancedPanel(
              snapshots: snapshots,
              result: currentResult,
            ),
            const SizedBox(height: 10),
            _buildCompactInfoPanel(
              isOverallSelected: isOverallSelected,
              result: currentResult,
              summary: overallSummary,
            ),
            const SizedBox(height: 10),
            _buildBottomResultStrip(
              isOverallSelected: isOverallSelected,
              result: currentResult,
              summary: overallSummary,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildCompactTopTabs() {
  final selectedMain = _mainCategoryIdOfSelected();

  final topItems = [
    {'id': 'overall', 'title': 'Умумий'},
    ..._calcGroups.map((g) => {'id': g.id, 'title': g.title}),
    {'id': 'floor_single', 'title': 'Пол'},
    {'id': 'ceiling_single', 'title': 'Потолок'},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: topItems.map((e) {
            final id = e['id'] as String;
            final selected = selectedMain == id;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    if (id == 'overall') {
                      _selectedCalcItemId = 'overall';
                    } else if (id == 'floor_single') {
                      _selectedCalcItemId = 'floor_single';
                    } else if (id == 'ceiling_single') {
                      _selectedCalcItemId = 'ceiling_single';
                    } else {
                      final g = _calcGroups.firstWhere((x) => x.id == id);
                      _selectedCalcItemId = g.items.first.id;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: selected
                        ? const Color(0xFF1BAE9D)
                        : const Color(0xFF12202B),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF74E8D8)
                          : SantexColors.borderSoft,
                    ),
                  ),
                  child: Text(
                    e['title'] as String,
                    style: TextStyle(
                      color: selected ? Colors.white : SantexColors.dimText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),

      if (selectedMain != 'overall' &&
          selectedMain != 'floor_single' &&
          selectedMain != 'ceiling_single') ...[
        const SizedBox(height: 8),
        _buildCompactSubTabs(selectedMain),
      ],
    ],
  );
}

Widget _buildCompactSubTabs(String groupId) {
  final group = _calcGroups.firstWhere((g) => g.id == groupId);

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: group.items.map((item) {
        final selected = _selectedCalcItemId == item.id;
        final savedQ = _elements[item.id]?.savedQ ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedCalcItemId = item.id;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected
                    ? const Color(0xFF16394A)
                    : const Color(0xFF0F1A24),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4A86D9)
                      : SantexColors.borderSoft,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? Colors.white : SantexColors.dimText,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${savedQ.toStringAsFixed(0)} Вт',
                    style: TextStyle(
                      color: selected ? Colors.white70 : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

Widget _compactDisplayField({
  required String label,
  required String value,
}) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SantexColors.label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SantexColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SantexColors.inputBorder),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: SantexColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _tapInputField({
  required String fieldKey,
  required String label,
  required String value,
  bool selected = false,
}) {
  final isActive = _activeInputKey == fieldKey;

  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          _activeInputKey = fieldKey;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SantexColors.label,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: SantexColors.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? SantexColors.blueBtn2
                    : SantexColors.inputBorder,
                width: isActive ? 1.6 : 1.0,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: value.isEmpty ? SantexColors.dimText : SantexColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCompactInputPanel({
  required Map<String, ElementSnapshot> snapshots,
  required ElementCalculationResult result,
  required OverallSavedSummary overallSummary,
}) {
  if (_selectedCalcItemId == 'overall') {
    return Column(
      children: [
        Row(
          children: [
            _tapInputField(
              fieldKey: 'overall_room_area',
              label: 'ХОНА МАЙДОНИ (м²)',
              value: _roomAreaController.text,
            ),
            const SizedBox(width: 8),
            _tapInputField(
              fieldKey: 'overall_room_height',
              label: 'ХОНА БАЛАНДЛИГИ (м)',
              value: _roomHeightController.text,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _tapInputField(
              fieldKey: 'overall_infiltration_ti',
              label: 'ИНФИЛЬТРАЦИЯ Ti (°C)',
              value: _infiltrationTempController.text,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ИНФИЛЬТРАЦИЯ K',
                    style: TextStyle(
                      color: SantexColors.label,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: SantexColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SantexColors.inputBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InfiltrationKOption>(
                        value: _selectedInfiltrationK,
                        isExpanded: true,
                        dropdownColor: SantexColors.card,
                        items: InfiltrationKOption.values.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text('k=${v.kValue}'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedInfiltrationK = v;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  final el = _elements[_selectedCalcItemId]!;
  final area = (_parse(el.heightController.text) ?? 0) *
      (_parse(el.lengthController.text) ?? 0);

  return Column(
    children: [
      Row(
        children: [
          _tapInputField(
            fieldKey: 'height',
            label: 'БАЛАНДЛИГИ (м)',
            value: el.heightController.text,
          ),
          const SizedBox(width: 8),
          _tapInputField(
            fieldKey: 'length',
            label: 'УЗУНЛИГИ (м)',
            value: el.lengthController.text,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЮЗАСИ (м²)',
                  style: TextStyle(
                    color: SantexColors.label,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101820),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SantexColors.inputBorder),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    area <= 0 ? '—' : _fmtDouble(area),
                    style: const TextStyle(
                      color: SantexColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _tapInputField(
            fieldKey: 'indoorTemp',
            label: 'ИЧКИ ҲАРОРАТ Ti (°C)',
            value: el.indoorTempController.text,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ТАШҚИ ҲАРОРАТ Tt (°C)',
                  style: TextStyle(
                    color: SantexColors.label,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: SantexColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SantexColors.inputBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: kOutdoorTempOptions.any(
                        (e) => e.city == el.selectedOutdoorCity,
                      )
                          ? el.selectedOutdoorCity
                          : null,
                      hint: const Text('Жадвалдан танлаш'),
                      isExpanded: true,
                      dropdownColor: SantexColors.card,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '__manual__',
                          child: Text('Қўлда киритиш'),
                        ),
                        ...kOutdoorTempOptions.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.city,
                            child: Text(
                              '${e.city} (${e.temp.toStringAsFixed(0)} °C)',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          if (value == '__manual__') {
                            el.selectedOutdoorCity = null;
                          } else {
                            el.selectedOutdoorCity = value;
                            final picked = kOutdoorTempOptions.firstWhere(
                              (e) => e.city == value,
                            );
                            el.outdoorTempController.text =
                                picked.temp.toStringAsFixed(0);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _tapInputField(
            fieldKey: 'outdoorTemp',
            label: 'Tt ҚЎЛДА',
            value: el.outdoorTempController.text,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ΔT = Ti - Tt',
                  style: TextStyle(
                    color: SantexColors.label,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101820),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SantexColors.inputBorder),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    result.deltaT == null ? '—' : _fmtDouble(result.deltaT!),
                    style: const TextStyle(
                      color: SantexColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox()),
        ],
      ),
    ],
  );
}


Widget _keyBtn({
  required String text,
  required VoidCallback onTap,
  Color bg = SantexColors.keypad,
  Color border = SantexColors.keypadBorder,
  Color textColor = SantexColors.text,
  double fontSize = 18,
  int flex = 1,
}) {
  return Expanded(
    flex: flex,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bg,
          border: Border.all(color: border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

Widget _buildSantexKeypad({
  required void Function(String value) onDigit,
}) {
  return Column(
    children: [
      Row(
        children: [
          _keyBtn(text: '7', onTap: () => _handleKey('7')),
          const SizedBox(width: 6),
          _keyBtn(text: '8', onTap: () => _handleKey('8')),
          const SizedBox(width: 6),
          _keyBtn(text: '9', onTap: () => _handleKey('9')),
          const SizedBox(width: 6),
          _keyBtn(
            text: '⌫',
            onTap: () => _handleKey('DEL'),
            bg: const Color(0xFF1A2430),
            border: const Color(0xFF5E6D7D),
            textColor: const Color(0xFFB8C8D8),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          _keyBtn(text: '4', onTap: () => _handleKey('4')),
          const SizedBox(width: 6),
          _keyBtn(text: '5', onTap: () => _handleKey('5')),
          const SizedBox(width: 6),
          _keyBtn(text: '6', onTap: () => _handleKey('6')),
          const SizedBox(width: 6),
          _keyBtn(
            text: '<>',
            onTap: () => _handleKey('±'),
            bg: const Color(0xFF1A2430),
            border: const Color(0xFF5E6D7D),
            textColor: const Color(0xFFB8C8D8),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          _keyBtn(text: '1', onTap: () => _handleKey('1')),
          const SizedBox(width: 6),
          _keyBtn(text: '2', onTap: () => _handleKey('2')),
          const SizedBox(width: 6),
          _keyBtn(text: '3', onTap: () => _handleKey('3')),
          const SizedBox(width: 6),
          _keyBtn(text: '.', onTap: () => _handleKey('.')),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          _keyBtn(text: '0', onTap: () => _handleKey('0')),
          const SizedBox(width: 6),
          _keyBtn(
            text: '=',
            onTap: _saveSelectedElementToOverall,
            bg: SantexColors.redBtn,
            border: SantexColors.redBorder,
            textColor: Colors.white,
            fontSize: 22,
          ),
          const SizedBox(width: 6),
          _keyBtn(
            text: 'ҲИСОБЛАШ',
            onTap: _calculateSelected,
            bg: SantexColors.blueBtn,
            border: SantexColors.blueBtn2,
            textColor: Colors.white,
            fontSize: 15,
            flex: 2,
          ),
        ],
      ),
    ],
  );
}

void _handleKey(String key) {
  TextEditingController? controller;

  if (_activeInputKey == null) return;

  if (_selectedCalcItemId == 'overall') {
    switch (_activeInputKey) {
      case 'overall_room_area':
        controller = _roomAreaController;
        break;
      case 'overall_room_height':
        controller = _roomHeightController;
        break;
      case 'overall_infiltration_ti':
        controller = _infiltrationTempController;
        break;
    }
  } else {
    final el = _elements[_selectedCalcItemId]!;

    switch (_activeInputKey) {
      case 'height':
        controller = el.heightController;
        break;
      case 'length':
        controller = el.lengthController;
        break;
      case 'indoorTemp':
        controller = el.indoorTempController;
        break;
      case 'outdoorTemp':
        controller = el.outdoorTempController;
        break;
      case 'beta':
        controller = el.betaSumController;
        break;
      case 'n':
        controller = el.nController;
        break;
      case 'r':
        controller = el.rController;
        break;
    }
  }

  if (controller == null) return;

  final text = controller.text;

  setState(() {
    if (key == 'DEL') {
      if (text.isNotEmpty) {
        controller!.text = text.substring(0, text.length - 1);
      }
    } else if (key == '.') {
      if (!text.contains('.')) {
        controller!.text = text.isEmpty ? '0.' : '$text.';
      }
    } else if (key == '±') {
      if (text.isEmpty) {
        controller!.text = '-';
      } else {
        controller!.text =
            text.startsWith('-') ? text.substring(1) : '-$text';
      }
    } else {
      controller!.text = '$text$key';
    }
  });
}

Widget _buildCompactAdvancedPanel({
  required Map<String, ElementSnapshot> snapshots,
  required ElementCalculationResult result,
}) {
  if (_selectedCalcItemId == 'overall') {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ҚЎШИМЧА ПАРАМЕТРЛАР',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: SantexColors.text,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<InfiltrationKOption>(
            value: _selectedInfiltrationK,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Инфильтрация k',
            ),
            items: InfiltrationKOption.values.map((value) {
              return DropdownMenuItem<InfiltrationKOption>(
                value: value,
                child: Text('${value.title}  (k=${value.kValue})'),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedInfiltrationK = value;
              });
            },
          ),
        ],
      ),
    );
  }

  final item = _itemMap[_selectedCalcItemId]!;
  final element = _elements[_selectedCalcItemId]!;

  final double currentAirLayerR = supportsAirLayerResistance(item.kind)
      ? airLayerResistanceValue(
          kind: item.kind,
          thickness: element.airLayerThickness,
          sign: element.airLayerSign,
        )
      : 0.0;

  final double currentBaseR = _parse(element.rController.text) ?? 0.0;
  final double currentTotalR = currentBaseR + currentAirLayerR;

  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ҚЎШИМЧА КОЭФФИЦИЕНТЛАР',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: SantexColors.text,
          ),
        ),
        const SizedBox(height: 10),

        if (item.kind.usesOrientation) ...[
          DropdownButtonFormField<FacingDirection>(
            value: element.direction,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Ориентация',
            ),
            items: FacingDirection.values
                .where((e) => e != FacingDirection.none)
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.title),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                element.direction = value;
              });
            },
          ),
          const SizedBox(height: 10),
        ],

        if (item.kind == CalcItemKind.externalWall) ...[
          DropdownButtonFormField<WallExtraOption>(
            value: element.wallExtraOption,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Девор қўшимча коэффициенти',
            ),
            items: WallExtraOption.values.map((value) {
              return DropdownMenuItem<WallExtraOption>(
                value: value,
                child: Text('${value.title} (${_fmtDouble(value.value)})'),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                element.wallExtraOption = value;
              });
            },
          ),
          const SizedBox(height: 10),
        ],

        if (item.kind == CalcItemKind.externalDoor) ...[
          DropdownButtonFormField<DoorExtraOption>(
            value: element.doorExtraOption,
            isExpanded: true,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Эшик қўшимча коэффициенти',
            ),
            items: DoorExtraOption.values.map((value) {
              return DropdownMenuItem<DoorExtraOption>(
                value: value,
                child: Text('${value.title} (${_fmtDouble(value.value)})'),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                element.doorExtraOption = value;
              });
            },
          ),
          const SizedBox(height: 10),
        ],

        if (_isSubtractedFromWall(item.kind)) ...[
          DropdownButtonFormField<String>(
            value: element.attachedWallId,
            dropdownColor: SantexColors.card,
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
          const SizedBox(height: 10),
        ],

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: element.betaSumController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Σβ',
                  hintText: 'масалан 0.05',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: element.rController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'R',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: element.nController,
                enabled: item.kind.usesN,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: item.kind.usesN ? 'n' : 'n ишламайди',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: SantexColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SantexColors.inputBorder),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'βор = ${_fmtDouble(result.orientationBeta)}',
                  style: const TextStyle(
                    color: SantexColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (supportsAirLayerResistance(item.kind)) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<AirLayerThickness>(
            value: element.airLayerThickness,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Ҳаво қатлами қалинлиги',
            ),
            items: AirLayerThickness.values.map((value) {
              return DropdownMenuItem(
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
          const SizedBox(height: 10),
          DropdownButtonFormField<AirLayerSign>(
            value: element.airLayerSign,
            dropdownColor: SantexColors.card,
            decoration: const InputDecoration(
              labelText: 'Ҳаво қатлами ишораси',
            ),
            items: AirLayerSign.values.map((value) {
              return DropdownMenuItem(
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
          const SizedBox(height: 10),
          Text(
            'Қўшимча R = ${_fmtDouble(currentAirLayerR)}    |    R умумий = ${_fmtDouble(currentTotalR)}',
            style: const TextStyle(
              color: SantexColors.dimText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );
}


Widget _buildCompactInfoPanel({
  required bool isOverallSelected,
  required ElementCalculationResult result,
  required OverallSavedSummary summary,
}) {
  String t1;
  String t2;
  String t3;

  if (isOverallSelected) {
    t1 = 'Хона майдони: ${_roomAreaController.text.isEmpty ? "-" : "${_roomAreaController.text} м²"}';
    t2 = 'Хона баландлиги: ${_roomHeightController.text.isEmpty ? "-" : "${_roomHeightController.text} м"}';
    t3 = 'Ташқи ҳарорат: ${_infiltrationTempController.text} °C';
  } else {
    final el = _elements[_selectedCalcItemId]!;
    t1 = 'Хона майдони: ${el.heightController.text.isEmpty ? "-" : el.heightController.text}';
    t2 = 'Девор қалинлиги: ${el.lengthController.text.isEmpty ? "-" : el.lengthController.text} мм';
    t3 = 'Ташқи ҳарорат: ${el.outdoorTempController.text} °C';
  }

  return GlassCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t1, style: const TextStyle(color: SantexColors.dimText, fontSize: 13)),
              const SizedBox(height: 3),
              Text(t2, style: const TextStyle(color: SantexColors.dimText, fontSize: 13)),
              const SizedBox(height: 3),
              Text(t3, style: const TextStyle(color: SantexColors.dimText, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(
          width: 92,
          child: SantexLogoHeader(),
        ),
      ],
    ),
  );
}

Widget _buildBottomResultStrip({
  required bool isOverallSelected,
  required ElementCalculationResult result,
  required OverallSavedSummary summary,
}) {
  final double q = isOverallSelected
      ? summary.overall
      : (result.q ?? _elements[_selectedCalcItemId]?.savedQ ?? 0);

  final int radiatorCount = q <= 0 ? 0 : (q / 1200).ceil();

  return Row(
    children: [
      Expanded(
        flex: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: SantexColors.greenPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F5A50)),
          ),
          child: Column(
            children: [
              const Text(
                'ЗАРУР ИССИҚЛИК ҚУВВАТИ',
                style: TextStyle(
                  color: SantexColors.label,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(q / 1000).toStringAsFixed(1)} кВт',
                style: const TextStyle(
                  color: SantexColors.greenText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: SantexColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SantexColors.border),
          ),
          child: Column(
            children: [
              const Text(
                'РАДИАТОРЛАР СОНИ (та)',
                style: TextStyle(
                  color: SantexColors.label,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$radiatorCount',
                style: const TextStyle(
                  color: SantexColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

 Widget _buildHeader() {
  return Column(
    children: const [
      SantexLogoHeader(),
      SizedBox(height: 12),
      Text(
        'ИСИТИШ ТИЗИМИ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: SantexColors.text,
          height: 1.05,
          letterSpacing: 0.4,
        ),
      ),
      SizedBox(height: 2),
      Text(
        'КАЛЬКУЛЯТОРИ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: SantexColors.text,
          height: 1.05,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

Widget _buildScreenTab() {
  final roomTitle = _roomNameController.text.trim().isNotEmpty
      ? _roomNameController.text.trim()
      : 'Хона ${widget.roomIndex + 1}';

  return Column(
    children: [
      GestureDetector(
        onTap: _openRoomSelector,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF9A8245),
            boxShadow: const [
              BoxShadow(
                color: Color(0x5529E0C2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.projectTitle} • $roomTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                _showRoomPicker
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
      if (_showRoomPicker) ...[
        const SizedBox(height: 10),
        _buildInlineRoomPicker(),
      ],
    ],
  );
}

Widget _buildInlineRoomPicker() {
  return GlassCard(
    padding: const EdgeInsets.all(10),
    child: SizedBox(
      height: 260,
      child: ListView.separated(
        itemCount: widget.projectRooms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final room = widget.projectRooms[index];
          final selected = index == widget.roomIndex;
          final title = room.roomName.trim().isNotEmpty
              ? room.roomName.trim()
              : room.roomTitle;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectRoomFromInlineList(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected
                    ? const Color(0xFF1EC6B3)
                    : const Color(0xFF0D2027),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7BF1DE)
                      : const Color(0xFF203B44),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selected
                          ? const Color(0xFF032129)
                          : const Color(0xFF10252D),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? const Color(0xFF032129) : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormatUz.watts(room.totalSavedQ),
                    style: TextStyle(
                      color: selected ? const Color(0xFF032129) : Colors.white60,
                      fontSize: 12,
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
      ],
    ),
  );
}

Widget _buildOverallRoomParamsCard() {
  return GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'УМУМИЙ ПАРАМЕТРЛАР',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _roomHeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Хона баландлиги, м',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _roomAreaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Хона юзаси, м²',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _infiltrationTempController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Инфильтрация учун Ti, °C',
          ),
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
      value: _overallSavedSummaryFromSnapshots(_workingSnapshots()).overall,
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mainItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.9,
        ),
        itemBuilder: (_, index) => mainItems[index],
      ),
      if (activeMain != 'overall' &&
          activeMain != 'floor_single' &&
          activeMain != 'ceiling_single') ...[
        const SizedBox(height: 10),
        _buildSelectedSubMenu(activeMain),
      ],
    ],
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
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              fontSize: 13,
              height: 1.15,
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

  final items = group.items.map((item) {
    final selected = _selectedCalcItemId == item.id;
    final total = _savedItemTotal(item.id);

    return GestureDetector(
      onTap: () => _selectCalcItem(item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                fontSize: 12,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              NumberFormatUz.watts(total),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }).toList();

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.9,
    ),
    itemBuilder: (_, index) => items[index],
  );
}

 Widget _buildSelectedElementInput({
  required Map<String, ElementSnapshot> snapshots,
  required ElementCalculationResult result,
}) {
  final item = _itemMap[_selectedCalcItemId]!;
  final element = _elements[_selectedCalcItemId]!;
  final soilForcedR = soilZoneResistanceById(item.id);

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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Хона ҳарорати Ti, °C',
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: kOutdoorTempOptions.any(
              (e) => e.city == element.selectedOutdoorCity,
            )
                ? element.selectedOutdoorCity
                : null,
            isExpanded: true,
            dropdownColor: const Color(0xFF0E2128),
            decoration: const InputDecoration(
              labelText: 'Шаҳар / ташқи ҳарорат',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '__manual__',
                child: Text('Қўлда киритиш'),
              ),
              ...kOutdoorTempOptions.map(
                (e) => DropdownMenuItem<String>(
                  value: e.city,
                  child: Text('${e.city}  (${e.temp.toStringAsFixed(0)} °C)'),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                if (value == '__manual__') {
                  element.selectedOutdoorCity = null;
                } else {
                  element.selectedOutdoorCity = value;
                  final picked = kOutdoorTempOptions.firstWhere(
                    (e) => e.city == value,
                  );
                  element.outdoorTempController.text =
                      picked.temp.toStringAsFixed(0);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: element.outdoorTempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Ташқи ҳарорат Tt, °C',
              hintText: 'Қўлда ўзгартириш мумкин',
            ),
            onChanged: (_) {
              element.selectedOutdoorCity = null;
            },
          ),
        ],
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

              if (item.kind == CalcItemKind.externalWall) ...[
  DropdownButtonFormField<WallExtraOption>(
    value: element.wallExtraOption,
    dropdownColor: const Color(0xFF0E2128),
    decoration: _editableDecoration('Девор учун қўшимча коэффициент'),
    items: WallExtraOption.values.map((value) {
      return DropdownMenuItem<WallExtraOption>(
        value: value,
        child: Text('${value.title} (${_fmtDouble(value.value)})'),
      );
    }).toList(),
    onChanged: (value) {
      if (value == null) return;
      setState(() {
        element.wallExtraOption = value;
      });
    },
  ),
  const SizedBox(height: 12),
],

if (item.kind == CalcItemKind.externalDoor) ...[
  DropdownButtonFormField<DoorExtraOption>(
    value: element.doorExtraOption,
    isExpanded: true,
    dropdownColor: const Color(0xFF0E2128),
    decoration: _editableDecoration('Эшик учун қўшимча коэффициент'),
    items: DoorExtraOption.values.map((value) {
      return DropdownMenuItem<DoorExtraOption>(
        value: value,
        child: Text('${value.title} (${_fmtDouble(value.value)})'),
      );
    }).toList(),
    onChanged: (value) {
      if (value == null) return;
      setState(() {
        element.doorExtraOption = value;
      });
    },
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
                   decoration: _editableDecoration(
  'Σβ',
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
    enabled: true,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: item.kind == CalcItemKind.soilZone
        ? _editableDecoration('R (тупроқ зонаси, ўзгартириш мумкин)')
        : _editableDecoration('Асосий R'),
  ),
),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: element.nController,
                    enabled: item.kind.usesN,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                   decoration: item.kind.usesN
    ? _editableDecoration('n')
    : _readonlyDecoration('n ишламайди'), 
                  ),
                ),
              ],
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

  Widget _buildOverallInfiltrationSettings({
  required Map<String, ElementSnapshot> snapshots,
}) {
  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);
  final double height = _parseOrZero(_roomHeightController.text);
  final double area = _parseOrZero(_roomAreaController.text);
  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltrationFromSnapshots(snapshots);
  final double qInf = _calculateOverallInfiltrationFromSnapshots(snapshots);

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
          isExpanded: true,
          dropdownColor: const Color(0xFF0E2128),
          decoration: const InputDecoration(
            labelText: 'k қўшимча коэффициент',
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
          items: InfiltrationKOption.values.map((value) {
            return DropdownMenuItem<InfiltrationKOption>(
              value: value,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  '${value.title}\n k = ${value.kValue}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ),
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
                title: 'Баландлик',
                value: '${_fmtDouble(height)} м',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _smallStat(
                title: 'Хона юзаси',
                value: '${_fmtDouble(area)} м²',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

  Widget _buildOverallCard(OverallSavedSummary summary) {

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

  Widget _buildOverallFormulaCard(
  OverallSavedSummary s,
  Map<String, ElementSnapshot> snapshots,
) {
  final double indoorTemp = _parseOrZero(_infiltrationTempController.text);
  final double height = _parseOrZero(_roomHeightController.text);
  final double area = _parseOrZero(_roomAreaController.text);
  final int normalizedTemp = normalizeIndoorTempForGi(indoorTemp);
  final double gi = giByIndoorTemp(normalizedTemp);
  final double maxDt = _maxPositiveDeltaTForInfiltrationFromSnapshots(snapshots);
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
          'Qинф = 0.28 × 1.005 × ((H × S) × Gi) × ΔTmax × k',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'H = ${_fmtDouble(height)}, '
          'S = ${_fmtDouble(area)}, '
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
  final int selectedRoomIndex;
  final void Function(int index) onSelectProject;
  final void Function(int index) onSelectRoom;

  const ProjectsScreen({
    super.key,
    required this.projects,
    required this.selectedProjectIndex,
    required this.selectedRoomIndex,
    required this.onSelectProject,
    required this.onSelectRoom,
  });

  double _projectTotal(ProjectRecord project) {
    double sum = 0;
    for (final room in project.rooms) {
      sum += room.totalSavedQ;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final activeProject = projects[selectedProjectIndex];

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
                'Лойиҳа танланг ва кейин хонага киринг.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final selected = selectedProjectIndex == index;
                    final totalQ = _projectTotal(project);

                    return SizedBox(
                      width: 250,
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          onTap: () => onSelectProject(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                    child: Text(
                                      project.slotTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Хоналар: ${project.rooms.length} та',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Умумий Q: ${NumberFormatUz.watts(totalQ)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                selected ? 'Танланган лойиҳа' : 'Танлаш',
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
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
              Text(
                '${activeProject.slotTitle} • Хоналар',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: ListView.separated(
                  itemCount: activeProject.rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = activeProject.rooms[index];
                    final selected = selectedRoomIndex == index;

                    return GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: InkWell(
                        onTap: () => onSelectRoom(index),
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
                                    room.displayTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Қават: ${room.floorNumber.isEmpty ? "-" : room.floorNumber}   •   Хона рақами: ${room.roomNumber.isEmpty ? "-" : room.roomNumber}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Q = ${NumberFormatUz.watts(room.totalSavedQ)}',
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


class CalculatorsHubScreen extends StatelessWidget {
  final VoidCallback onOpenHeatLoss;

  const CalculatorsHubScreen({
    super.key,
    required this.onOpenHeatLoss,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'КАЛЬКУЛЯТОРЛАР',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Керакли калькуляторни танланг.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),

            _CalculatorHubTile(
              title: 'Теплопотери',
              subtitle: 'Иссиқлик йўқотишлари ҳисоби',
              icon: Icons.whatshot_rounded,
              isReady: true,
              onTap: onOpenHeatLoss,
            ),
            const SizedBox(height: 12),

            _CalculatorHubTile(
              title: 'Гидравлика',
              subtitle: 'Ҳозирча бўш',
              icon: Icons.water_drop_rounded,
              isReady: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Гидравлика калькулятори ҳали қўшилмаган'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _CalculatorHubTile(
              title: 'Вентиляция',
              subtitle: 'Ҳозирча бўш',
              icon: Icons.air_rounded,
              isReady: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Вентиляция калькулятори ҳали қўшилмаган'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _CalculatorHubTile(
              title: 'Сантехника',
              subtitle: 'Ҳозирча бўш',
              icon: Icons.plumbing_rounded,
              isReady: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Сантехника калькулятори ҳали қўшилмаган'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorHubTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isReady;
  final VoidCallback onTap;

  const _CalculatorHubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isReady
                    ? const Color(0xFF1EC6B3)
                    : const Color(0xFF10252D),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isReady ? const Color(0xFF032129) : Colors.white70,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isReady ? 'Очиш' : 'Тез кунда',
              style: TextStyle(
                color: isReady ? const Color(0xFF4EF0D1) : Colors.white38,
                fontWeight: FontWeight.w700,
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
      padding: padding ?? const EdgeInsets.all(14),
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SantexColors.card2, SantexColors.card],
        ),
        border: Border.all(color: SantexColors.border, width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SantexLogoHeader extends StatelessWidget {
  const SantexLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFF2F3F5), Color(0xFFD9DDE2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: const Color(0xFFB8C0C8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8A2F37), width: 2),
            ),
            child: const Icon(Icons.home_work_outlined, color: Color(0xFF22384F), size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'SANTEX',
                style: TextStyle(
                  color: Color(0xFF21466B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 20,
                  height: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'PROFI-SERVIS',
                style: TextStyle(
                  color: Color(0xFF4F5560),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  fontSize: 9,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
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