import 'package:flutter/material.dart';

import 'recipes/dropdown_recipe.dart';
import 'recipes/placement_playground.dart';
import 'recipes/popover_recipe.dart';
import 'recipes/select_recipe.dart';
import 'recipes/tooltip_recipe.dart';

void main() => runApp(const ExampleApp());

/// One entry in the recipe gallery.
class Recipe {
  const Recipe(this.id, this.title, this.subtitle, this.icon, this.builder);
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

final recipes = <Recipe>[
  Recipe('playground', 'Placement playground',
      'All 12 placements + flip/shift toggles', Icons.grid_view_outlined,
      (_) => const PlacementPlayground()),
  Recipe('tooltip', 'Tooltip',
      'Hover / long-press tooltip with an arrow', Icons.info_outline,
      (_) => const TooltipRecipe()),
  Recipe('dropdown', 'Dropdown menu',
      'Button → menu, dismiss on outside tap',
      Icons.arrow_drop_down_circle_outlined, (_) => const DropdownRecipe()),
  Recipe('select', 'Select field',
      'Options flip up when the field is near the bottom',
      Icons.checklist_outlined, (_) => const SelectRecipe()),
  Recipe('popover', 'Popover card',
      'Rich card with an arrow; pick any side', Icons.chat_bubble_outline,
      (_) => const PopoverRecipe()),
];

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Deep-link a single recipe via ?demo=<id> (handy for docs screenshots and
    // for sharing a specific demo). Falls back to the gallery.
    final demo = Uri.base.queryParameters['demo'];
    final matches = recipes.where((r) => r.id == demo);

    return MaterialApp(
      title: 'anchor_kit example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: matches.isNotEmpty ? matches.first.builder(context) : const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('anchor_kit — recipes')),
      body: ListView.separated(
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = recipes[i];
          return ListTile(
            leading: CircleAvatar(child: Icon(r.icon)),
            title: Text(r.title),
            subtitle: Text(r.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: r.builder)),
          );
        },
      ),
    );
  }
}
