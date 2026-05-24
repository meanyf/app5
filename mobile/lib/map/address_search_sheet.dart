import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class AddressSearchSheet extends StatefulWidget {
  final Future<void> Function(String query) onAddressSelected;

  const AddressSearchSheet({required this.onAddressSelected});

  @override
  State<AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<AddressSearchSheet> {
  final _controller = TextEditingController();
  List<SuggestItem> _suggests = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _suggests = []);
      return;
    }

    final (_, result) = await YandexSuggest.getSuggestions(
      text: value,
      boundingBox: const BoundingBox(
        southWest: Point(latitude: 55.4913, longitude: 37.2421),
        northEast: Point(latitude: 55.9578, longitude: 37.9674),
      ),
      suggestOptions: const SuggestOptions(
        suggestType: SuggestType.geo,
        strictBounds: true,
      ),
    );

    final suggestResult = await result;
    debugPrint('error: ${suggestResult.error}');
    debugPrint('items count: ${suggestResult.items?.length}');
    debugPrint('first item: ${suggestResult.items?.firstOrNull?.title}');
    if (suggestResult.error != null) return;
    if (!mounted) return;
    setState(() => _suggests = suggestResult.items ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Введите адрес',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onChanged,
            onSubmitted: (value) {
              Navigator.pop(context);
              widget.onAddressSelected(value);
            },
          ),
          if (_suggests.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 270),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _suggests.length,
                itemBuilder: (_, i) {
                  final suggest = _suggests[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(suggest.title),
                    subtitle: suggest.subtitle != null
                        ? Text(suggest.subtitle!)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAddressSelected(suggest.displayText);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
