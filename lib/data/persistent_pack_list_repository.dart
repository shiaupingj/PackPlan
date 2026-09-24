import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/pack_item.dart';
import '../models/pack_list.dart';
import '../models/pack_template.dart';
import '../models/user_settings.dart';
import '../services/backup_codec.dart';
import 'pack_list_repository.dart';
import 'pack_plan_database_store.dart';

class PersistentPackListRepository extends ChangeNotifier
    implements PackListRepository {
  PersistentPackListRepository._({
    required PackPlanStateStore store,
    required InMemoryPackListRepository delegate,
  }) : _store = store,
       _delegate = delegate {
    _delegate.addListener(_handleChange);
  }

  final PackPlanStateStore _store;
  final InMemoryPackListRepository _delegate;
  Future<void> _saveTail = Future.value();
  Object? _lastSaveError;

  static Future<PersistentPackListRepository> open(
    PackPlanStateStore store,
  ) async {
    final savedBytes = await store.load();
    if (savedBytes == null) {
      final repository = PersistentPackListRepository._(
        store: store,
        delegate: InMemoryPackListRepository(),
      );
      repository._queueSave(repository._snapshot());
      await repository.flush();
      return repository;
    }

    final backup = BackupCodec.decode(savedBytes);
    return PersistentPackListRepository._(
      store: store,
      delegate: InMemoryPackListRepository(
        initialLists: backup.lists,
        initialSettings: backup.settings,
      ),
    );
  }

  @visibleForTesting
  Object? get lastSaveError => _lastSaveError;

  @override
  bool get hasSaveError => _lastSaveError != null;

  @override
  List<PackList> get lists => _delegate.lists;

  @override
  List<PackTemplate> get templates => _delegate.templates;

  @override
  UserSettings get settings => _delegate.settings;

  @override
  PackList? findById(String id) => _delegate.findById(id);

  @override
  void updateSettings(UserSettings settings) {
    _delegate.updateSettings(settings);
  }

  @override
  void replaceAllData({
    required List<PackList> lists,
    required UserSettings settings,
  }) {
    _delegate.replaceAllData(lists: lists, settings: settings);
  }

  @override
  void renameList(String listId, String title) {
    _delegate.renameList(listId, title);
  }

  @override
  void updateTripSettings(
    String listId, {
    required int days,
    required Set<WeatherCondition> weatherConditions,
    bool? showWeight,
  }) {
    _delegate.updateTripSettings(
      listId,
      days: days,
      weatherConditions: weatherConditions,
      showWeight: showWeight,
    );
  }

  @override
  bool renameCategory(String listId, String currentName, String newName) {
    return _delegate.renameCategory(listId, currentName, newName);
  }

  @override
  void reorderCategories(String listId, List<String> orderedCategoryNames) {
    _delegate.reorderCategories(listId, orderedCategoryNames);
  }

  @override
  List<PackItem> previewItemsForDraft({
    required PackTemplate template,
    required int days,
    required Set<WeatherCondition> weatherConditions,
  }) {
    return _delegate.previewItemsForDraft(
      template: template,
      days: days,
      weatherConditions: weatherConditions,
    );
  }

  @override
  PackList createFromTemplate(PackTemplate template) {
    return _delegate.createFromTemplate(template);
  }

  @override
  PackList createFromDraft(CreatePackListDraft draft) {
    return _delegate.createFromDraft(draft);
  }

  @override
  PackList? duplicateList(String listId) {
    return _delegate.duplicateList(listId);
  }

  @override
  void deleteList(String listId) {
    _delegate.deleteList(listId);
  }

  @override
  void toggleItem(String listId, String itemId, bool checked) {
    _delegate.toggleItem(listId, itemId, checked);
  }

  @override
  void upsertItem(String listId, PackItem item) {
    _delegate.upsertItem(listId, item);
  }

  @override
  void upsertItems(String listId, List<PackItem> items) {
    _delegate.upsertItems(listId, items);
  }

  @override
  void deleteItem(String listId, String itemId) {
    _delegate.deleteItem(listId, itemId);
  }

  @override
  void reorderItems(String listId, List<PackItem> reorderedItems) {
    _delegate.reorderItems(listId, reorderedItems);
  }

  void _handleChange() {
    _queueSave(_snapshot());
    notifyListeners();
  }

  Uint8List _snapshot() {
    return BackupCodec.encode(lists: lists, settings: settings);
  }

  void _queueSave(Uint8List bytes) {
    _saveTail = _saveTail
        .then((_) => _store.save(bytes))
        .then<void>((_) => _updateSaveError(null))
        .catchError((Object error, StackTrace stackTrace) {
          _updateSaveError(error);
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'PackPlan persistence',
              context: ErrorDescription('while saving the local database'),
            ),
          );
        });
  }

  /// 只在「正常 ↔ 失敗」轉換時通知，避免每次寫入都觸發 rebuild。
  void _updateSaveError(Object? error) {
    final hadError = _lastSaveError != null;
    _lastSaveError = error;
    if (hadError != (error != null)) {
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<void> flush() => _saveTail;

  Future<void> close() async {
    await flush();
    await _store.close();
  }

  @override
  void dispose() {
    _delegate.removeListener(_handleChange);
    _delegate.dispose();
    super.dispose();
  }
}
