import 'package:flutter/material.dart';
import 'material_reference_data.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialReferenceSection> get _filteredSections {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kMaterialReferenceSections;

    return kMaterialReferenceSections
        .map((section) {
          final items = section.items.where((item) {
            final hay = [
              item.name,
              item.density,
              item.lambdaDry,
              item.lambdaA,
              item.lambdaB,
              item.r,
              item.notes ?? '',
            ].join(' ').toLowerCase();

            return hay.contains(q);
          }).toList();

          return MaterialReferenceSection(title: section.title, items: items);
        })
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _filteredSections;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'МАЪЛУМОТНОМА',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Қурилиш материалларининг теплотехник кўрсаткичлари',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildFormulaCard(),
            const SizedBox(height: 12),
            _buildBrickFormatsCard(),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Материал қидириш',
                hintText: 'масалан: бетон, пенопласт, ғишт...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              const _EmptySearchState()
            else
              ...sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReferenceSectionCard(section: section),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122730), Color(0xFF0A1B22)],
        ),
        border: Border.all(color: const Color(0xFF1E3943)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'АСОСИЙ ФОРМУЛА',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Rмат = δ / λ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4EF0D1),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'R — иссиқлик ўтказишга қаршилик\n'
            'δ — материал қалинлиги\n'
            'λ — теплопроводность коэффициенти',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrickFormatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122730), Color(0xFF0A1B22)],
        ),
        border: Border.all(color: const Color(0xFF1E3943)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ҒИШТ ЎЛЧАМЛАРИ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ...kBrickFormats.map(
            (brick) => Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                    brick.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ValueChip(label: 'Узунлиги', value: '${brick.length} мм'),
                      _ValueChip(label: 'Кенглиги', value: '${brick.width} мм'),
                      _ValueChip(label: 'Баландлиги', value: '${brick.height} мм'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceSectionCard extends StatelessWidget {
  final MaterialReferenceSection section;

  const _ReferenceSectionCard({
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122730), Color(0xFF0A1B22)],
        ),
        border: Border.all(color: const Color(0xFF1E3943)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: section.items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _MaterialCard(item: item),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialReferenceItem item;

  const _MaterialCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
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
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ValueChip(label: 'ρ', value: '${item.density} кг/м³'),
              _ValueChip(label: 'C0', value: item.specificHeat),
              _ValueChip(label: 'λ қуруқ', value: item.lambdaDry),
              _ValueChip(label: 'λ A', value: item.lambdaA),
              _ValueChip(label: 'λ Б', value: item.lambdaB),
              _ValueChip(label: 'R', value: item.r),
            ],
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.notes!,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _ValueChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10252D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF294752)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF0D2027),
        border: Border.all(color: const Color(0xFF203B44)),
      ),
      child: const Text(
        'Қидирув бўйича материал топилмади.',
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}