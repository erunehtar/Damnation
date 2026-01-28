# Damnation

### Blessing of Salvation management for tanks

A lightweight addon that removes unwanted buffs automatically. For instance, cancelling Blessing of Salvation manually, especially from Paladins who do not announce it, can drive one insane and can make tanking miserable.

## Features

### Three operating modes

- **Always:** Always remove managed buffs
- **When Tanking:** Remove managed buffs only when tanking (Warriors in Defensive Stance, Druids in Bear Form, Paladins with Righteous Fury)
- **Never:** Never remove managed buffs

### Custom Buff Groups

You can create your own custom buff groups to remove any unwanted buffs automatically. Each buff group act like a virtual container where you can add any number of spell IDs. When any buff from the group is detected on player, Damnation will attempt remove it.

### Announcements

You can toggle announcing when Damnation removes an unwanted buff. You can also choose to announce when a buff could not be removed because player is in combat.

### Remove Other Unwanted Buffs

Additional unwanted buffs can also be removed. Check user interface options for more details.

### Profiles

You can setup as many profiles as you want and easily setup a different profile per character or per class.

### Slash Commands

Slash commands are supported. Type `/dmn` or `/damnation` for help about slash command options.

## Limitations

Unfortunately, Blizzard disallow addons from removing buffs while player is in combat. However, Damnation will remove unwanted buffs as soon as player leave combat.

## License

This library is released under the MIT License. See the LICENSE file for details.
