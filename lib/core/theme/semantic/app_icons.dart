import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every icon of the app, named by its role, not by its glyph.
///
/// The only file that imports an icon package: a glyph, a stroke weight or
/// the pack itself changes here, never in a widget. Two roles may share a
/// glyph (a playlist and the queue); give each its own entry anyway, so one
/// can change without the other.
///
/// Lucide is the base.
abstract final class AppIcons {
  // ── Playback ──────────────────────────────────────────────────────────────
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData skipNext = LucideIcons.skipForward;
  static const IconData shuffle = LucideIcons.shuffle;
  static const IconData queue = LucideIcons.listMusic;
  static const IconData playNext = LucideIcons.listStart;
  static const IconData addToQueue = LucideIcons.listEnd;
  static const IconData history = LucideIcons.history;
  static const IconData sleepTimer = LucideIcons.timer;
  static const IconData speed = LucideIcons.gauge;
  static const IconData volumeLow = LucideIcons.volume1;

  /// On the row of the song that is playing.
  static const IconData nowPlaying = LucideIcons.music2;

  // ── Library ───────────────────────────────────────────────────────────────
  /// A song, and the placeholder of a song without a cover.
  static const IconData track = LucideIcons.music;

  /// An album, and the placeholder of an album without a cover.
  static const IconData album = LucideIcons.disc;

  /// An artist, and the placeholder of an artist without a photo.
  static const IconData artist = LucideIcons.micVocal;
  static const IconData playlist = LucideIcons.listMusic;
  static const IconData like = LucideIcons.heart;
  static const IconData unlike = LucideIcons.heartOff;
  static const IconData addToPlaylist = LucideIcons.listPlus;
  static const IconData removeFromList = LucideIcons.listX;
  static const IconData lossless = LucideIcons.audioWaveform;
  static const IconData listen = LucideIcons.headphones;
  static const IconData artistBio = LucideIcons.user;
  static const IconData similarArtists = LucideIcons.users;
  static const IconData releaseDate = LucideIcons.calendar;
  static const IconData duration = LucideIcons.clock;
  static const IconData recent = LucideIcons.clock;
  static const IconData libraryAll = LucideIcons.galleryVerticalEnd;

  // ── Navigation ────────────────────────────────────────────────────────────
  static const IconData home = LucideIcons.house;
  static const IconData library = LucideIcons.library;
  static const IconData search = LucideIcons.search;
  static const IconData settings = LucideIcons.settings;
  static const IconData back = LucideIcons.chevronLeft;

  /// Leads to another page (a row, a card).
  static const IconData disclosure = LucideIcons.chevronRight;
  static const IconData expand = LucideIcons.chevronDown;
  static const IconData collapse = LucideIcons.chevronUp;
  static const IconData openExternal = LucideIcons.externalLink;
  static const IconData systemSettings = LucideIcons.settings2;

  // ── Actions ───────────────────────────────────────────────────────────────
  /// Options of a row.
  static const IconData more = LucideIcons.ellipsis;

  /// Options of a page, in its header.
  static const IconData moreVertical = LucideIcons.ellipsisVertical;
  static const IconData close = LucideIcons.x;

  /// Empties a field.
  static const IconData clear = LucideIcons.circleX;
  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData selected = LucideIcons.check;
  static const IconData dragHandle = LucideIcons.gripVertical;
  static const IconData sort = LucideIcons.arrowDownNarrowWide;
  static const IconData listView = LucideIcons.layoutList;
  static const IconData gridView = LucideIcons.layoutGrid;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData reset = LucideIcons.rotateCcw;

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const IconData info = LucideIcons.info;
  static const IconData noResults = LucideIcons.searchX;
  static const IconData highlight = LucideIcons.sparkles;
  static const IconData hint = LucideIcons.sparkle;

  // ── Features and settings ─────────────────────────────────────────────────
  static const IconData stats = LucideIcons.barChart3;
  static const IconData weeklyRecap = LucideIcons.calendarHeart;
  static const IconData monthlyReplay = LucideIcons.calendarSync;
  static const IconData whatsNew = LucideIcons.sparkles;
  static const IconData update = LucideIcons.circleArrowUp;
  static const IconData glassEffect = LucideIcons.sparkles;
  static const IconData pauseOnCall = LucideIcons.phoneOff;
  static const IconData resumeAfterCall = LucideIcons.phoneCall;
  static const IconData haptics = LucideIcons.vibrate;
  static const IconData biographies = LucideIcons.bookOpen;
  static const IconData photos = LucideIcons.image;
  static const IconData clearCovers = LucideIcons.imageOff;
  static const IconData clearOnlineInfo = LucideIcons.eraser;
  static const IconData backup = LucideIcons.hardDriveUpload;
  static const IconData restore = LucideIcons.archiveRestore;
  static const IconData report = LucideIcons.messageSquareWarning;
  static const IconData privacy = LucideIcons.shieldCheck;
  static const IconData licenses = LucideIcons.scrollText;
  static const IconData storageAccess = LucideIcons.folderLock;
}
