# TASKS.md — Текущие задачи

> AI-агенты читают этот файл перед началом работы.
> Текущий этап: **Этап 1 — Autoloads и скелет**

---

## В работе

- [ ] Настроить защиту ветки `main` на GitHub (вручную, через Settings → Branches)

---

## Следующие задачи (Этап 1)

- [ ] Создать `scripts/autoloads/event_bus.gd` — шина событий
- [ ] Создать `scripts/autoloads/game_manager.gd` — глобальное состояние
- [ ] Создать `scripts/autoloads/save_system.gd` — сохранение
- [ ] Зарегистрировать Autoloads в `project.godot`
- [ ] Создать `scripts/core/unit_data.gd` — Resource-класс юнита
- [ ] Создать `scripts/core/enemy_data.gd` — Resource-класс врага
- [ ] Создать `scripts/core/node_data.gd` — Resource-класс нода карты
- [ ] Создать `scenes/main/main.tscn` — базовая главная сцена

---

## Завершено

- [x] Инициализация репозитория
- [x] Создание `.gitignore` (Godot 4 + секреты + OS)
- [x] Создание `.gitattributes`
- [x] Создание `AGENTS.md` (правила агентов + архитектурные правила)
- [x] Создание `SECURITY.md`
- [x] Создание `README.md`
- [x] Создание `CONTRIBUTING.md`
- [x] Создание `GAME_DESIGN.md` (концепция, сеттинг, механики)
- [x] Создание `ROADMAP.md`
- [x] Создание `CHANGELOG.md`
- [x] Создание структуры папок
- [x] Создание `project.godot` (Godot 4, 1280×720, Landscape)
- [x] Создание `icon.svg`
- [x] Создание веток `main` и `dev` на GitHub
- [x] Создание `ai/prompts/lead_architect.md` (системный промпт)
- [x] Создание `docs/architecture.md` (EventBus API, схема модулей)
- [x] Создание `docs/battle_formula.md` (формула автобоя)
- [x] Создание `docs/hero_memory.md` (механика памяти героя)
- [x] Обновление `AGENTS.md` — архитектурные правила
- [x] Добавление папки `data/`
- [x] Добавление папки `scripts/autoloads/`

---

## Заблокировано / Ожидает решения

- Типы ресурсов базы — уточнить у владельца (еда? металл? реликвии?)
- Размер отряда — уточнить (ориентир 4-8 юнитов)
- Дизайн первого нода карты для тестирования

---

## Заметки для агентов

- Перед работой читать: `AGENTS.md`, `docs/architecture.md`, `ai/prompts/lead_architect.md`
- Рабочие ветки: `agent/описание` или `claude/описание`
- Межмодульная коммуникация: только через `EventBus`
- Никогда не пушить в `main`
