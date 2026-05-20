# Архитектура BeforeGods

## Схема модулей

```
┌─────────────────────────────────────────────────────────┐
│                      AUTOLOADS                          │
│  EventBus   │   GameManager   │   SaveSystem            │
└────────────────────┬────────────────────────────────────┘
                     │ signals
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │   MAP   │  │ BATTLE  │  │  BASE   │
   │ Module  │  │ Module  │  │ Module  │
   └─────────┘  └─────────┘  └─────────┘
```

Модули **не импортируют** друг друга напрямую.
Вся коммуникация — только через `EventBus`.

---

## Autoload-синглтоны

| Синглтон | Файл | Назначение |
|----------|------|-----------|
| `EventBus` | `scripts/autoloads/event_bus.gd` | Шина событий между модулями |
| `GameManager` | `scripts/autoloads/game_manager.gd` | Глобальное состояние игры |
| `SaveSystem` | `scripts/autoloads/save_system.gd` | Сохранение/загрузка данных |

Регистрация в `project.godot`:
```
[autoload]
EventBus="*res://scripts/autoloads/event_bus.gd"
GameManager="*res://scripts/autoloads/game_manager.gd"
SaveSystem="*res://scripts/autoloads/save_system.gd"
```

---

## EventBus: полный список сигналов (MVP)

```gdscript
class_name EventBus
extends Node

# === MAP MODULE ===
signal squad_moved(from_node: String, to_node: String)
signal node_entered(node_id: String)
signal node_event_triggered(event_data: Dictionary)

# === BATTLE MODULE ===
signal battle_started(enemy_data: Dictionary)
signal battle_ended(result: String)   # "win" | "narrow_win" | "retreat" | "defeat"
signal unit_died(unit_id: String)
signal hero_died()

# === BASE MODULE ===
signal resource_changed(resource_type: String, delta: int)
signal building_upgraded(building_id: String)
signal squad_healed(unit_id: String, amount: int)

# === HERO MEMORY ===
signal hero_memory_lost(lost_keys: Array[String])
signal hero_respawned(penalties: Dictionary)

# === SYSTEM ===
signal game_saved()
signal game_loaded()
signal scene_transition_requested(scene_path: String)
```

---

## Map Module

**Папка:** `scenes/world/`, `scripts/systems/map_system.gd`

**Подход:** Граф нодов (не AStar2D — для фиксированного графа это избыточно).
Навигация через BFS / Dijkstra по `Dictionary[String, Array[String]]`.

```gdscript
# Структура графа
var node_connections: Dictionary = {
    "camp": ["ruins_north", "oasis_east"],
    "ruins_north": ["camp", "temple"],
    ...
}
```

**Нод карты** — `Resource` (`NodeData`):
```gdscript
class_name NodeData
extends Resource
var node_id: String
var node_type: String        # "city" | "ruins" | "oasis" | "temple"
var combat_difficulty: float # 0.8 — 1.5
var events: Array[String]    # список возможных ивентов
var is_visited: bool
```

---

## Battle Module

**Папка:** `scenes/characters/`, `scripts/systems/battle_system.gd`

Детальная формула автобоя — в `docs/battle_formula.md`.

**Режимы боя:**
- `auto` — быстрое разрешение по формуле (основной режим MVP)
- `tactical` — пошаговая сетка (расширенный режим, пост-MVP)

---

## Base Module

**Папка:** `scenes/ui/`, `scripts/systems/base_ui.gd`

**Паттерн:** State Machine. Каждый экран базы — отдельная сцена:
```
scenes/ui/base/
├── base_main.tscn       # Главный экран базы
├── base_healing.tscn    # Экран лечения
├── base_buildings.tscn  # Экран зданий
├── base_equipment.tscn  # Экран экипировки
└── base_roster.tscn     # Экран состава отряда
```

---

## SaveSystem

**Слотов:** 1 (roguelite-стиль, автосохранение)
**Триггер:** После каждого посещённого нода

**Разделение данных:**
- `persistent_data` — выживает после смерти героя (постройки базы, исследованные регионы)
- `run_data` — теряется при смерти героя (XP, навыки, квестовая память, состав отряда)

---

## Правила для агентов

1. Никаких прямых ссылок между модулями (`Map`, `Battle`, `Base`)
2. Всё через `EventBus.emit_signal(...)` или `EventBus.connect(...)`
3. Данные — через `Resource` классы, не через словари (кроме ивент-данных)
4. Autoload-синглтоны доступны глобально по имени: `EventBus`, `GameManager`, `SaveSystem`
