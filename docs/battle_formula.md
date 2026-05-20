# Формула автобоя (Battle Formula)

## Обзор

BeforeGods использует систему **автобоя** как основной режим для MVP.
Бой не разворачивается пошагово — он разрешается за один расчёт с элементом случайности.

---

## Формула

```
battle_result = squad_score vs enemy_score
```

### squad_score

```gdscript
func calculate_squad_score(squad: Array[UnitData]) -> float:
    var raw_power: int = 0
    for unit in squad:
        raw_power += unit.atk + unit.level * 2
    var morale_mod: float = lerp(0.7, 1.3, squad.morale / 100.0)
    var dice: int = randi_range(-5, 5)
    return (raw_power * morale_mod) + dice
```

### enemy_score

```gdscript
func calculate_enemy_score(enemy: EnemyData, node: NodeData) -> float:
    var terrain_mod: float = node.combat_difficulty  # 0.8 .. 1.5
    var dice: int = randi_range(-5, 5)
    return (enemy.base_power * terrain_mod) + dice
```

---

## Исходы боя

| Условие | Исход | Описание |
|---------|-------|----------|
| `squad_score > enemy_score * 1.3` | `win` | Победа без потерь или с минимальными |
| `squad_score > enemy_score` | `narrow_win` | Победа, но с ранеными юнитами |
| `squad_score == enemy_score ± 2` | `draw` | Ничья — обе стороны отступают |
| `squad_score < enemy_score` | `retreat` | Отряд отступает, теряет часть ресурсов |
| `squad_score < enemy_score * 0.7` | `defeat` | Разгром — высокий риск гибели юнитов |

---

## Параметры юнита (UnitData)

```gdscript
class_name UnitData
extends Resource

var unit_id: String
var unit_name: String
var level: int = 1
var atk: int = 5
var hp: int = 100
var hp_max: int = 100
var morale: int = 80        # 0-100, влияет на squad_score
var is_alive: bool = true
var injuries: Array[String] # перманентные травмы (пост-MVP)
var equipment: Array[String]
```

---

## Параметры врага (EnemyData)

```gdscript
class_name EnemyData
extends Resource

var enemy_id: String
var enemy_name: String
var base_power: int = 20    # базовая сила группы врагов
var lore_text: String       # мифологическое описание
var drop_resources: Dictionary
```

---

## Последствия боя

### При `win` / `narrow_win`
- Получить ресурсы из `enemy.drop_resources`
- При `narrow_win`: случайные юниты получают ранения (снижение HP)
- Испустить `EventBus.battle_ended("win")` или `"narrow_win"`

### При `retreat`
- Потеря 10-20% текущих ресурсов
- Моральный штраф отряду (`morale -= 10`)
- Возврат на предыдущий нод карты

### При `defeat`
- Бросок кубика смерти для каждого юнита: шанс гибели = `(enemy_score - squad_score) * 2%`
- При гибели: `EventBus.unit_died(unit.unit_id)` → юнит удаляется навсегда
- Если погиб герой: `EventBus.hero_died()` → запускается механика памяти

---

## Мораль отряда

Мораль влияет на `morale_mod` и изменяется после каждого боя:

| Событие | Изменение морали |
|---------|-----------------|
| `win` | `+10` |
| `narrow_win` | `+3` |
| `draw` | `0` |
| `retreat` | `-10` |
| `defeat` | `-20` |
| Гибель товарища | `-5` за каждого |
| Отдых на базе | `+15` |
| Еда и ресурсы | `+5` |

---

## Расширение (пост-MVP)

- Учёт типов оружия (рубящее vs колющее vs дробящее)
- Погода и время суток как `terrain_mod` модификаторы
- Специальные способности юнитов (активируются при определённых условиях)
- Пошаговый тактический режим для особых сражений
