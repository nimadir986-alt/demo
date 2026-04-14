import 'package:flutter/foundation.dart';

@immutable
class MaterialReferenceItem {
  final String name;
  final String density;
  final String specificHeat;
  final String lambdaDry;
  final String lambdaA;
  final String lambdaB;
  final String r;
  final String? notes;

  const MaterialReferenceItem({
    required this.name,
    required this.density,
    required this.specificHeat,
    required this.lambdaDry,
    required this.lambdaA,
    required this.lambdaB,
    required this.r,
    this.notes,
  });
}

@immutable
class MaterialReferenceSection {
  final String title;
  final List<MaterialReferenceItem> items;

  const MaterialReferenceSection({
    required this.title,
    required this.items,
  });
}

@immutable
class BrickFormatItem {
  final String title;
  final String length;
  final String width;
  final String height;

  const BrickFormatItem({
    required this.title,
    required this.length,
    required this.width,
    required this.height,
  });
}

const List<BrickFormatItem> kBrickFormats = [
  BrickFormatItem(
    title: 'Одинарный (Бир ғишт)',
    length: '250',
    width: '120',
    height: '65',
  ),
  BrickFormatItem(
    title: 'Полуторный (Бир ярим ғишт)',
    length: '250',
    width: '120',
    height: '88',
  ),
];

const List<MaterialReferenceSection> kMaterialReferenceSections = [
  MaterialReferenceSection(
    title: 'I. Бетон ва қоришмалар',
    items: [
      MaterialReferenceItem(
        name: 'Железобетон',
        density: '2500',
        specificHeat: '0.84',
        lambdaDry: '1.69',
        lambdaA: '1.92',
        lambdaB: '2.04',
        r: '0.20833',
      ),
      MaterialReferenceItem(
        name: 'Бетон на гравии или щебне из природного камня',
        density: '2400',
        specificHeat: '0.84',
        lambdaDry: '1.51',
        lambdaA: '1.74',
        lambdaB: '1.86',
        r: '0.22989',
      ),
      MaterialReferenceItem(
        name: 'Керамзитобетон на керамзитовом песке',
        density: '1800',
        specificHeat: '0.84',
        lambdaDry: '0.66',
        lambdaA: '0.80',
        lambdaB: '0.92',
        r: '0.50',
      ),
      MaterialReferenceItem(
        name: 'Керамзитобетон на керамзитовом песке',
        density: '1600',
        specificHeat: '0.84',
        lambdaDry: '0.58',
        lambdaA: '0.67',
        lambdaB: '0.79',
        r: '0.59701',
      ),
      MaterialReferenceItem(
        name: 'Газо- ва пенобетон',
        density: '1000',
        specificHeat: '0.84',
        lambdaDry: '0.29',
        lambdaA: '0.41',
        lambdaB: '0.47',
        r: '0.97561',
      ),
      MaterialReferenceItem(
        name: 'Газо- ва пенобетон',
        density: '800',
        specificHeat: '0.84',
        lambdaDry: '0.21',
        lambdaA: '0.33',
        lambdaB: '0.37',
        r: '1.21212',
      ),
      MaterialReferenceItem(
        name: 'Вермикулитобетон',
        density: '800',
        specificHeat: '0.84',
        lambdaDry: '0.21',
        lambdaA: '0.23',
        lambdaB: '0.26',
        r: '1.73913',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'II. Цементли, известли ва гипсли қоришмалар',
    items: [
      MaterialReferenceItem(
        name: 'Цементно-песчаный раствор',
        density: '1800',
        specificHeat: '0.84',
        lambdaDry: '0.58',
        lambdaA: '0.76',
        lambdaB: '0.93',
        r: '0.02632',
      ),
      MaterialReferenceItem(
        name: 'Сложный раствор (песок, известь, цемент)',
        density: '1700',
        specificHeat: '0.84',
        lambdaDry: '0.52',
        lambdaA: '0.70',
        lambdaB: '0.87',
        r: '0.57143',
      ),
      MaterialReferenceItem(
        name: 'Известково-песчаный раствор',
        density: '1600',
        specificHeat: '0.84',
        lambdaDry: '0.47',
        lambdaA: '0.70',
        lambdaB: '0.81',
        r: '0.57143',
      ),
      MaterialReferenceItem(
        name: 'Плиты из гипса',
        density: '1200',
        specificHeat: '0.84',
        lambdaDry: '0.35',
        lambdaA: '0.41',
        lambdaB: '0.47',
        r: '0.97561',
      ),
      MaterialReferenceItem(
        name: 'Листы гипсовые обшивочные',
        density: '800',
        specificHeat: '0.84',
        lambdaDry: '0.15',
        lambdaA: '0.19',
        lambdaB: '0.21',
        r: '2.10526',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'III. Кирпич, тош ва кладка',
    items: [
      MaterialReferenceItem(
        name: 'Глиняный обыкновенный кирпич на цементно-песчаном растворе',
        density: '1800',
        specificHeat: '0.88',
        lambdaDry: '0.56',
        lambdaA: '0.70',
        lambdaB: '0.81',
        r: '0.57143',
      ),
      MaterialReferenceItem(
        name: 'Силикатный кирпич на цементно-песчаном растворе',
        density: '1800',
        specificHeat: '0.88',
        lambdaDry: '0.70',
        lambdaA: '0.76',
        lambdaB: '0.87',
        r: '0.52632',
      ),
      MaterialReferenceItem(
        name: 'Керамический пустотный кирпич',
        density: '1600',
        specificHeat: '0.88',
        lambdaDry: '0.47',
        lambdaA: '0.58',
        lambdaB: '0.64',
        r: '0.68966',
      ),
      MaterialReferenceItem(
        name: 'Гранит, гнейс и базальт',
        density: '2800',
        specificHeat: '0.88',
        lambdaDry: '3.49',
        lambdaA: '3.49',
        lambdaB: '3.49',
        r: '0.11461',
      ),
      MaterialReferenceItem(
        name: 'Мрамор',
        density: '2800',
        specificHeat: '0.88',
        lambdaDry: '2.91',
        lambdaA: '2.91',
        lambdaB: '2.91',
        r: '0.13746',
      ),
      MaterialReferenceItem(
        name: 'Известняк',
        density: '2000',
        specificHeat: '0.88',
        lambdaDry: '0.93',
        lambdaA: '1.16',
        lambdaB: '1.28',
        r: '0.34483',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'IV. Ёғоч ва органик материаллар',
    items: [
      MaterialReferenceItem(
        name: 'Сосна и ель поперек волокон',
        density: '500',
        specificHeat: '2.3',
        lambdaDry: '0.09',
        lambdaA: '0.14',
        lambdaB: '0.18',
        r: '2.85714',
      ),
      MaterialReferenceItem(
        name: 'Сосна и ель вдоль волокон',
        density: '500',
        specificHeat: '2.3',
        lambdaDry: '0.18',
        lambdaA: '0.29',
        lambdaB: '0.35',
        r: '1.37931',
      ),
      MaterialReferenceItem(
        name: 'Дуб поперек волокон',
        density: '700',
        specificHeat: '2.3',
        lambdaDry: '0.10',
        lambdaA: '0.18',
        lambdaB: '0.23',
        r: '2.22222',
      ),
      MaterialReferenceItem(
        name: 'Дуб вдоль волокон',
        density: '700',
        specificHeat: '2.3',
        lambdaDry: '0.23',
        lambdaA: '0.35',
        lambdaB: '0.41',
        r: '1.14286',
      ),
      MaterialReferenceItem(
        name: 'Фанера клееная',
        density: '600',
        specificHeat: '2.3',
        lambdaDry: '0.12',
        lambdaA: '0.15',
        lambdaB: '0.18',
        r: '2.66667',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'V. Теплоизоляцион материаллар',
    items: [
      MaterialReferenceItem(
        name: 'Маты минераловатные',
        density: '125',
        specificHeat: '0.84',
        lambdaDry: '0.056',
        lambdaA: '0.064',
        lambdaB: '0.070',
        r: '6.25',
      ),
      MaterialReferenceItem(
        name: 'Маты минераловатные',
        density: '75',
        specificHeat: '0.84',
        lambdaDry: '0.052',
        lambdaA: '0.060',
        lambdaB: '0.064',
        r: '6.66667',
      ),
      MaterialReferenceItem(
        name: 'Маты минераловатные',
        density: '50',
        specificHeat: '0.84',
        lambdaDry: '0.048',
        lambdaA: '0.052',
        lambdaB: '0.060',
        r: '7.69231',
      ),
      MaterialReferenceItem(
        name: 'Минераловатные плиты',
        density: '350',
        specificHeat: '0.84',
        lambdaDry: '0.091',
        lambdaA: '0.090',
        lambdaB: '0.110',
        r: '4.44444',
      ),
      MaterialReferenceItem(
        name: 'Стекловолокнистые плиты',
        density: '50',
        specificHeat: '0.84',
        lambdaDry: '0.056',
        lambdaA: '0.060',
        lambdaB: '0.064',
        r: '6.66667',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'VI. Полимер материаллар',
    items: [
      MaterialReferenceItem(
        name: 'Пенополистирол',
        density: '150',
        specificHeat: '1.34',
        lambdaDry: '0.050',
        lambdaA: '0.052',
        lambdaB: '0.060',
        r: '7.69231',
      ),
      MaterialReferenceItem(
        name: 'Пенополистирол',
        density: '100',
        specificHeat: '1.34',
        lambdaDry: '0.041',
        lambdaA: '0.041',
        lambdaB: '0.052',
        r: '9.7561',
      ),
      MaterialReferenceItem(
        name: 'Пенополиуретан',
        density: '80',
        specificHeat: '1.47',
        lambdaDry: '0.041',
        lambdaA: '0.050',
        lambdaB: '0.050',
        r: '8.0',
      ),
      MaterialReferenceItem(
        name: 'Пенополиуретан',
        density: '60',
        specificHeat: '1.47',
        lambdaDry: '0.035',
        lambdaA: '0.041',
        lambdaB: '0.041',
        r: '9.7561',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'VII. Засыпкалар',
    items: [
      MaterialReferenceItem(
        name: 'Гравий керамзитовый',
        density: '800',
        specificHeat: '0.84',
        lambdaDry: '0.18',
        lambdaA: '0.21',
        lambdaB: '0.23',
        r: '1.90476',
      ),
      MaterialReferenceItem(
        name: 'Гравий керамзитовый',
        density: '600',
        specificHeat: '0.84',
        lambdaDry: '0.14',
        lambdaA: '0.17',
        lambdaB: '0.20',
        r: '2.35294',
      ),
      MaterialReferenceItem(
        name: 'Вермикулит вспученный',
        density: '200',
        specificHeat: '0.84',
        lambdaDry: '0.076',
        lambdaA: '0.090',
        lambdaB: '0.110',
        r: '4.44444',
      ),
      MaterialReferenceItem(
        name: 'Песок для строительных работ',
        density: '1600',
        specificHeat: '0.84',
        lambdaDry: '0.35',
        lambdaA: '0.47',
        lambdaB: '0.58',
        r: '0.85106',
      ),
      MaterialReferenceItem(
        name: 'Пеностекло / газостекло',
        density: '400',
        specificHeat: '0.84',
        lambdaDry: '0.11',
        lambdaA: '0.12',
        lambdaB: '0.14',
        r: '3.33333',
      ),
    ],
  ),
  MaterialReferenceSection(
    title: 'VIII. Металл ва шиша',
    items: [
      MaterialReferenceItem(
        name: 'Сталь стержневая арматурная',
        density: '7850',
        specificHeat: '0.482',
        lambdaDry: '58',
        lambdaA: '58',
        lambdaB: '58',
        r: '0.0069',
      ),
      MaterialReferenceItem(
        name: 'Чугун',
        density: '7200',
        specificHeat: '0.482',
        lambdaDry: '50',
        lambdaA: '50',
        lambdaB: '50',
        r: '0.008',
      ),
      MaterialReferenceItem(
        name: 'Алюминий',
        density: '2600',
        specificHeat: '0.84',
        lambdaDry: '221',
        lambdaA: '221',
        lambdaB: '221',
        r: '0.00181',
      ),
      MaterialReferenceItem(
        name: 'Медь',
        density: '8500',
        specificHeat: '0.42',
        lambdaDry: '407',
        lambdaA: '407',
        lambdaB: '407',
        r: '0.00098',
      ),
      MaterialReferenceItem(
        name: 'Стекло оконное',
        density: '2500',
        specificHeat: '0.84',
        lambdaDry: '0.76',
        lambdaA: '0.76',
        lambdaB: '0.76',
        r: '0.52632',
      ),
    ],
  ),
];