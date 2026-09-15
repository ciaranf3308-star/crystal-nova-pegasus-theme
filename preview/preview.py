#!/usr/bin/env python3
"""Render the Crystal Nova Pegasus theme headlessly with a mock Pegasus api.

Usage:
    preview.py --out shot.png [--keys Right,Down,Return] [--n 9|18]
               [--battery 0.73] [--charging] [--nobattery] [--delay 120]

The mock api mirrors the real Pegasus theme API surface (verified against
pegasus-frontend master):
  api.collections  -> ObjectListModel, roles: modelData/name/shortName/sortBy/
                      summary/description/extra/assets/games; .get(i), .count
  api.keys         -> isLeft/isRight/isUp/isDown/isAccept/isCancel/isDetails/
                      isFilters/isNextPage/isPrevPage/isPageUp/isPageDown/isMenu
  api.device       -> batteryPercent (float 0..1), batteryCharging (bool),
                      batteryStatus (int enum)
  api.memory       -> get/set/has/unset
"""
import os
import sys
import time
import argparse

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import (QObject, QAbstractListModel, QModelIndex, Qt,
                            QUrl, QCoreApplication, QEvent, Slot, Property,
                            Signal)
from PySide6.QtGui import QGuiApplication, QKeyEvent
from PySide6.QtQuick import QQuickView
from PySide6.QtQml import QJSValue

THEME_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Phase 1.6 preview dataset: real production systems only. Page 1 is the
# brief's mandated lineup; page 2 is another 9 from the asset set. A couple
# of page-2 shortNames deliberately use aliases ("32X", "TG16") to prove
# the IconResolver end-to-end in renders.
PAGE1 = [
    ("Game Boy Advance", "gba", 42),
    ("Super Nintendo", "snes", 128),
    ("PlayStation", "ps1", 96),
    ("Nintendo 64", "n64", 61),
    ("Dreamcast", "dreamcast", 33),
    ("PlayStation Portable", "psp", 54),
    ("Arcade", "arcade", 210),
    ("Nintendo DS", "nds", 40),
    ("PlayStation 2", "ps2", 60),
]
PAGE2 = [
    ("Sega Genesis", "GENESIS", 88),
    ("Sega CD", "SEGACD", 12),
    ("Sega 32X", "32X", 8),
    ("Sega Saturn", "SATURN", 24),
    ("PC Engine", "TG16", 15),
    ("Game Boy", "GB", 30),
    ("Game Boy Color", "GBC", 22),
    ("Nintendo Entertainment System", "NES", 35),
    ("Nintendo Wii", "WII", 28),
]

ROLE_NAMES = {
    Qt.UserRole + 0: b"modelData",
    Qt.UserRole + 1: b"name",
    Qt.UserRole + 2: b"shortName",
    Qt.UserRole + 3: b"sortBy",
    Qt.UserRole + 4: b"summary",
    Qt.UserRole + 5: b"description",
    Qt.UserRole + 6: b"extra",
    Qt.UserRole + 7: b"assets",
    Qt.UserRole + 8: b"games",
}


class MockGames(QObject):
    def __init__(self, count, parent=None):
        super().__init__(parent)
        self._count = count

    def _get_count(self):
        return self._count

    count = Property(int, _get_count, constant=True)


class MockCollection(QObject):
    def __init__(self, name, short_name, game_count, parent=None):
        super().__init__(parent)
        self._name = name
        self._short = short_name
        self._games = MockGames(game_count, self)

    def _get_name(self):
        return self._name

    def _get_short(self):
        return self._short

    def _get_games(self):
        return self._games

    name = Property(str, _get_name, constant=True)
    shortName = Property(str, _get_short, constant=True)
    games = Property(QObject, _get_games, constant=True)


class MockCollections(QAbstractListModel):
    countChanged = Signal()

    def __init__(self, items, parent=None):
        super().__init__(parent)
        self._items = [MockCollection(n, s, g, self) for n, s, g in items]

    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._items)

    def roleNames(self):
        return ROLE_NAMES

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        c = self._items[index.row()]
        r = role - Qt.UserRole
        return [c, c._name, c._short, c._short, "", "", {}, None, c._games][r]

    def _get_count(self):
        return len(self._items)

    count = Property(int, _get_count, notify=countChanged)

    @Slot(int, result=QObject)
    def get(self, idx):
        return self._items[idx] if 0 <= idx < len(self._items) else None


class MockKeys(QObject):
    # Mirrors the api.keys surface the theme is allowed to use. Directional
    # input is handled in QML via event.key === Qt.Key_Left/Right/Up/Down,
    # per the Pegasus docs — not via api.keys.
    MAP = {
        "isAccept": (Qt.Key_Return, Qt.Key_Enter),
        "isCancel": (Qt.Key_Escape,),
        "isPrevPage": (Qt.Key_PageUp,),
        "isNextPage": (Qt.Key_PageDown,),
    }

    def _check(self, name, event):
        # event arrives as QJSValue wrapping QML KeyEvent; read .key property.
        try:
            if isinstance(event, QJSValue):
                key = event.property("key").toInt()
            else:
                key = event.key if not callable(getattr(event, "key", None)) else event.key()
        except Exception:
            return False
        return key in self.MAP[name]

    @Slot(QJSValue, result=bool)
    def isAccept(self, e): return self._check("isAccept", e)

    @Slot(QJSValue, result=bool)
    def isCancel(self, e): return self._check("isCancel", e)

    @Slot(QJSValue, result=bool)
    def isPrevPage(self, e): return self._check("isPrevPage", e)

    @Slot(QJSValue, result=bool)
    def isNextPage(self, e): return self._check("isNextPage", e)


class MockDevice(QObject):
    def __init__(self, percent, charging, parent=None):
        super().__init__(parent)
        self._p = percent
        self._c = charging

    def _get_percent(self): return self._p
    def _get_charging(self): return self._c
    def _get_status(self): return 2  # Discharging

    batteryPercent = Property(float, _get_percent, constant=True)
    batteryCharging = Property(bool, _get_charging, constant=True)
    batteryStatus = Property(int, _get_status, constant=True)


class MockMemory(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._d = {}

    @Slot(str, result="QVariant")
    def get(self, k): return self._d.get(k)

    @Slot(str, result=bool)
    def has(self, k): return k in self._d

    @Slot(str, QJSValue)
    def set(self, k, v):
        try:
            v = v.toVariant()
        except Exception:
            pass
        self._d[k] = v

    @Slot(str)
    def unset(self, k): self._d.pop(k, None)


class MockApi(QObject):
    def __init__(self, n, battery, charging, parent=None, restore=None):
        super().__init__(parent)
        items = (PAGE1 + PAGE2) if n == 18 else (PAGE1 if n == 9 else [])
        self._collections = MockCollections(items, self)
        self._all_games = MockCollections([], self)
        self._keys = MockKeys(self)
        self._device = MockDevice(battery, charging, self)
        self._memory = MockMemory(self)
        if restore:
            # Pre-seed api.memory so the theme's onCompleted restore path runs.
            self._memory._d["crystalNova.lastSystem"] = restore

    def _get_collections(self): return self._collections
    def _get_all_games(self): return self._all_games
    def _get_keys(self): return self._keys
    def _get_device(self): return self._device
    def _get_memory(self): return self._memory

    collections = Property(QObject, _get_collections, constant=True)
    allGames = Property(QObject, _get_all_games, constant=True)
    keys = Property(QObject, _get_keys, constant=True)
    device = Property(QObject, _get_device, constant=True)
    memory = Property(QObject, _get_memory, constant=True)
    tr = Property(str, lambda self: "", constant=True)


KEYS = {
    "Up": Qt.Key_Up, "Down": Qt.Key_Down, "Left": Qt.Key_Left,
    "Right": Qt.Key_Right, "Return": Qt.Key_Return, "Enter": Qt.Key_Enter,
    "Escape": Qt.Key_Escape, "PageUp": Qt.Key_PageUp, "PageDown": Qt.Key_PageDown,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--keys", default="")
    ap.add_argument("--n", type=int, default=9, choices=(0, 9, 18))
    ap.add_argument("--battery", type=float, default=0.73)
    ap.add_argument("--charging", action="store_true")
    ap.add_argument("--nobattery", action="store_true")
    ap.add_argument("--delay", type=int, default=120, help="ms between key events")
    ap.add_argument("--settle", type=int, default=600, help="ms before grab")
    ap.add_argument("--restore", default="",
                    help="pre-seed api.memory crystalNova.lastSystem with a shortName")
    ap.add_argument("--print-state", action="store_true",
                    help="print screen/selectedIndex/page as KEY=VALUE for tests")
    args = ap.parse_args()

    battery = -1.0 if args.nobattery else args.battery

    app = QGuiApplication(sys.argv)
    api = MockApi(args.n, battery, args.charging,
                  restore=args.restore or None)

    view = QQuickView()
    view.engine().rootContext().setContextProperty("api", api)
    # NOTE: on first load you may see transient QML TypeErrors like
    # "Cannot read property 'collections' of null" plus Image "Cannot open"
    # warnings for icon paths with an empty shortName. This is a PySide6-only
    # harness quirk (first QML touch of a Python-provided context property can
    # race); the bindings recover and the final rendered state is correct.
    # Real Pegasus exposes api as a stable C++ object and does not do this.
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.setSource(QUrl.fromLocalFile(os.path.join(THEME_DIR, "theme.qml")))
    if view.status() != QQuickView.Ready:
        for e in view.errors():
            print("QML ERROR:", e.toString(), file=sys.stderr)
        sys.exit(2)
    view.resize(1280, 960)
    view.show()
    view.requestActivate()
    app.processEvents()
    time.sleep(0.4)
    app.processEvents()

    from PySide6.QtTest import QTest
    for name in [k.strip() for k in args.keys.split(",") if k.strip()]:
        code = KEYS[name]
        QTest.keyClick(view, code)
        QTest.qWait(args.delay)

    time.sleep(args.settle / 1000.0)
    app.processEvents()
    app.processEvents()

    img = view.grabWindow()
    if img.isNull():
        print("grabWindow returned null image", file=sys.stderr)
        sys.exit(3)
    img.save(args.out)
    print("saved", args.out, img.size().width(), "x", img.size().height())

    if args.print_state:
        from PySide6.QtQuick import QQuickItem
        root = view.rootObject()
        grid = root.findChild(QQuickItem, "systemGrid")
        state = {
            "screen": root.property("screen"),
            "selectedIndex": grid.property("globalIndex") if grid else None,
            "page": grid.property("page") if grid else None,
        }
        for k, v in state.items():
            print(f"STATE {k}={v}")


if __name__ == "__main__":
    main()
