# CHANGELOG.md

Все значимые изменения проекта фиксируются здесь.
Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

---

## [Unreleased]

### Added
- Инициализация репозитория
- Структура папок проекта
- `.gitignore` для Godot 4
- Документация: README, AGENTS, SECURITY, CONTRIBUTING, GAME_DESIGN, ROADMAP, TASKS
- `project.godot`: разрешение 1280×720, Landscape, регистрация Autoloads
- `ai/prompts/lead_architect.md` — системный промпт архитектора
- `docs/architecture.md` — схема модулей и EventBus API
- `docs/battle_formula.md` — детальная формула автобоя
- `docs/hero_memory.md` — механика памяти героя
- `GAME_DESIGN.md` заполнен: концепция, сеттинг, механики
- `AGENTS.md` обновлён: архитектурные правила, именование, пути
- Папки `data/` и `scripts/autoloads/`

### [Unreleased] — Этап 1: Autoloads и скелет

#### Added
- `scripts/autoloads/event_bus.gd` — шина событий (все сигналы MVP)
- `scripts/autoloads/game_manager.gd` — глобальное состояние, отряд, ресурсы, мораль
- `scripts/autoloads/save_system.gd` — persistent/run разделение, логика гибели героя
- `scripts/core/unit_data.gd` — Resource-класс юнита
- `scripts/core/enemy_data.gd` — Resource-класс врага
- `scripts/core/node_data.gd` — Resource-класс нода карты
- `scripts/core/main.gd` — точка входа
- `scenes/main/main.tscn` — главная сцена
- `project.godot`: main_scene подключена
