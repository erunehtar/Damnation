# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2020-07-14
### Changed
- Complete addon re-write, which now use Ace 3.0 lib.
- Added user interface.
- Added profiles support.
- Reworked how additional buffs removal is configured.
- Update interface version to 1.13.5

### Fixed
- Regression that caused unmanaged buffs to be removed.

## [1.3.0] - 2020-07-05
### Fixed
- Moved unnecessary buffs removal to separate list (duh!).

## [1.3.0] - 2020-07-04
### Added
- Added new option to remove unnecessary buffs, such as Blessing of Wisdom, Prayer of Spirit and Arcane Intellect.

### Changed
- Removed addon loaded message.
- Update interface version to 1.13.4

## [1.2.2] - 2019-12-12
### Changed
- Update interface version to 1.13.3

## [1.2.1] - 2019-11-08
### Fixed
- When mode is "auto", watch events will no longer be registered if the class is not Warrior, Druid or Paladin.

## [1.2.0] - 2019-10-26
### Fixed
- Fix issue with options not getting saved.
- Fix typo Damnation help text.

## [1.1.0] - 2019-10-25
### Added
- Damnation will now also remove Blessing of Salvation when player leave combat.

### Changed
- Global variable for Damnation options has been renamed to avoid conflicts with other addons.

### Fixed
- Blessing of Salvation will no longer be removed if the player is in combat, this is blocked by Blizzard.
- Removed dead code.

## [1.0.0] - 2019-10-20
### Added
- Initial release of Damnation.
